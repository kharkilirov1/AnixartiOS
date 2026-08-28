import Foundation
import os

struct APIError: Error, LocalizedError {
    let code: Int
    let message: String

    var errorDescription: String? { message }

    static func message(for code: Int, domain: String = "") -> String {
        switch code {
        case 401: return "Требуется авторизация"
        case 404: return "Не найдено"
        default: return "Ошибка сервера (код \(code))"
        }
    }
}

/// Central Anixart API client.
/// - Sign + User-Agent headers on every request (verified against production).
/// - Session token attached as `token` query parameter.
/// - Application-level error codes inside HTTP 200 bodies.
final class APIClient: @unchecked Sendable {

    static let shared = APIClient()

    // MARK: Diagnostics (shown in DiagnosticsView, mirrored to os_log)

    private static let logger = Logger(subsystem: "com.kharki.anixart", category: "api")
    private static let logQueue = DispatchQueue(label: "com.kharki.anixart.diag")
    static private(set) var recentErrors: [String] = []

    static func logError(_ message: String) {
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(stamp)] \(message)"
        logger.error("ANIX \(line, privacy: .public)")
        logQueue.sync {
            recentErrors.append(line)
            if recentErrors.count > 50 { recentErrors.removeFirst(recentErrors.count - 50) }
        }
    }

    static func lastErrorsSnapshot() -> [String] {
        logQueue.sync { recentErrors }
    }

    // MARK: Base URL with automatic failover (mirrors Android IS_API_ALT behavior)

    static let primaryBase = "https://api-s.anixsekai.com/"
    static let altBase = "https://api-s2.anixart.tv/"
    private static let baseKey = "apiBase"

    static var activeBase: String {
        UserDefaults.standard.string(forKey: baseKey) ?? primaryBase
    }

    /// Manual override used by the Diagnostics screen.
    static func setBase(_ url: String) {
        UserDefaults.standard.set(url, forKey: baseKey)
        Self.logError("Base URL переключён вручную: \(url)")
    }

    static func toggleBase() {
        setBase(activeBase == primaryBase ? altBase : primaryBase)
    }

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let baseURLProvider: () -> String

    var authToken: String? { TokenStore.load() }

    init(baseURLProvider: @escaping () -> String = { APIClient.activeBase }) {
        self.baseURLProvider = baseURLProvider
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 40
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    // MARK: - Core request

    private func buildURL(base: String, path: String, query: [String: String?]) -> URL? {
        var comps = URLComponents(string: base + path)
        var items = comps?.queryItems ?? []
        for (key, value) in query {
            if let value { items.append(URLQueryItem(name: key, value: value)) }
        }
        if let token = authToken {
            items.append(URLQueryItem(name: "token", value: token))
        } else if path != "config/toggles" && !path.hasPrefix("auth/") {
            items.append(URLQueryItem(name: "token", value: ""))
        }
        comps?.queryItems = items
        return comps?.url
    }

    /// Request with automatic failover: a network-level failure on the primary
    /// base URL is retried once against the alt API (persisted on success).
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: [String: String?] = [:],
        body: Data? = nil,
        asForm form: [String: String]? = nil
    ) async throws -> T {
        let base = baseURLProvider()
        do {
            return try await perform(path, base: base, method: method, query: query, body: body, form: form)
        } catch let urlError as URLError {
            let fallback: String = base == Self.primaryBase ? Self.altBase : Self.primaryBase
            Self.logError("Failover \(path): \(urlError.localizedDescription), пробуем \(fallback)")
            let result: T = try await perform(path, base: fallback, method: method, query: query, body: body, form: form)
            if UserDefaults.standard.string(forKey: Self.baseKey) != fallback {
                UserDefaults.standard.set(fallback, forKey: Self.baseKey)
                Self.logError("Base URL переключён автоматически: \(fallback)")
            }
            return result
        }
    }

    private func perform<T: Decodable>(
        _ path: String,
        base: String,
        method: String,
        query: [String: String?],
        body: Data?,
        form: [String: String]?
    ) async throws -> T {
        guard let url = buildURL(base: base, path: path, query: query) else {
            throw APIError(code: -1, message: "Некорректный URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(PoliceSign.userAgent(), forHTTPHeaderField: "User-Agent")
        req.setValue(PoliceSign.make(), forHTTPHeaderField: "Sign")
        if let form {
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = form.map { "\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $1)" }
                .joined(separator: "&").data(using: .utf8)
        } else if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        } else if method == "POST" {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = Data("{}".utf8)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            let nsCode = (error as? URLError)?.code.rawValue ?? -1
            Self.logError("Network \(path): \(error.localizedDescription) [URLError \(nsCode)]")
            throw error
        }
        guard let http = response as? HTTPURLResponse else {
            Self.logError("Нет HTTP-ответа: \(path)")
            throw APIError(code: -2, message: "Нет ответа сервера")
        }
        let bodySnippet = String(data: data.prefix(300), encoding: .utf8) ?? "<binary \(data.count) bytes>"
        guard (200..<300).contains(http.statusCode) else {
            Self.logError("HTTP \(http.statusCode) \(req.httpMethod ?? "") \(path) | \(bodySnippet)")
            throw APIError(code: http.statusCode, message: "HTTP \(http.statusCode)")
        }
        do {
            let result = try decoder.decode(T.self, from: data)
            Self.logger.debug("ANIX ok \(path, privacy: .public) (\(http.statusCode))")
            return result
        } catch {
            // Body may be a plain envelope {"code":N} while T is a model — surface app-level code.
            if let envelope = try? decoder.decode(CodeEnvelope.self, from: data), let code = envelope.code, code != 0 {
                Self.logError("AppCode \(code) \(path) | \(bodySnippet)")
                throw APIError(code: code, message: APIError.message(for: code))
            }
            Self.logError("Decode \(String(describing: T.self)) \(path): \(error.localizedDescription) | \(bodySnippet)")
            throw error
        }
    }

    private struct CodeEnvelope: Decodable { let code: Int? }

    func encodeBody<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }

    // MARK: - Auth

    func signIn(login: String, password: String) async throws -> SignInResponse {
        try await request("auth/signIn", method: "POST", asForm: ["login": login, "password": password])
    }

    func signUp(login: String, email: String, password: String) async throws -> SignUpResponse {
        try await request("auth/signUp", method: "POST", asForm: ["login": login, "email": email, "password": password])
    }

    func verify(login: String, email: String, password: String, hash: String, code: String) async throws -> SignInResponse {
        try await request("auth/verify", method: "POST", asForm: [
            "login": login, "email": email, "password": password, "hash": hash, "code": code,
        ])
    }

    func resend(login: String, email: String, password: String, hash: String) async throws -> CodeEnvelopeResponse {
        try await request("auth/resend", method: "POST", asForm: [
            "login": login, "email": email, "password": password, "hash": hash,
        ])
    }

    func restore(data: String) async throws -> SignUpResponse {
        try await request("auth/restore", method: "POST", asForm: ["data": data])
    }

    func restoreVerify(data: String, password: String, hash: String, code: String) async throws -> SignInResponse {
        try await request("auth/restore/verify", method: "POST", asForm: [
            "data": data, "password": password, "hash": hash, "code": code,
        ])
    }

    // MARK: - Config

    func toggles() async throws -> Toggles {
        try await request("config/toggles", query: [
            "version_code": "26032112",
            "is_beta": "false",
            "is_api_alt": "false",
        ])
    }

    // MARK: - Catalog

    func release(id: Int) async throws -> ReleaseWrapper {
        try await request("release/\(id)", query: ["extended_mode": "true"])
    }

    func randomRelease() async throws -> ReleaseWrapper {
        try await request("release/random", query: ["extended_mode": "true"])
    }

    func schedule() async throws -> ScheduleResponse {
        try await request("schedule")
    }

    func filter(page: Int, _ body: FilterRequestDTO) async throws -> Pageable<Release> {
        try await request("filter/\(page)", method: "POST", body: encodeBody(body))
    }

    func related(releaseId: Int, page: Int) async throws -> Pageable<Release> {
        try await request("related/\(releaseId)/\(page)")
    }

    func types() async throws -> EpisodeTypesWrapper {
        try await request("type/all")
    }

    // MARK: - Discover

    func recommendations(page: Int) async throws -> Pageable<Release> {
        try await request("discover/recommendations/\(page)", method: "POST", query: ["previous_page": String(page - 1)])
    }

    func watchingFeed(page: Int) async throws -> Pageable<Release> {
        try await request("discover/watching/\(page)", method: "POST")
    }

    func discussingFeed(page: Int) async throws -> Pageable<Release> {
        try await request("discover/discussing/\(page)", method: "POST")
    }

    // MARK: - Search

    func searchReleases(query: String, page: Int) async throws -> Pageable<Release> {
        try await request("search/releases/\(page)", method: "POST", body: encodeBody(SearchRequestDTO(query: query)))
    }

    func searchCollections(query: String, page: Int) async throws -> Pageable<Collection> {
        try await request("search/collections/\(page)", method: "POST", body: encodeBody(SearchRequestDTO(query: query)))
    }

    func searchProfiles(query: String, page: Int) async throws -> Pageable<Profile> {
        try await request("search/profiles/\(page)", method: "POST", body: encodeBody(SearchRequestDTO(query: query)))
    }

    // MARK: - Episodes

    func episodeTypes(releaseId: Int) async throws -> EpisodeTypesWrapper {
        try await request("episode/\(releaseId)")
    }

    func episodeSources(releaseId: Int, typeId: Int) async throws -> EpisodeSourcesWrapper {
        try await request("episode/\(releaseId)/\(typeId)")
    }

    func episodes(releaseId: Int, typeId: Int, sourceId: Int) async throws -> EpisodesWrapper {
        try await request("episode/\(releaseId)/\(typeId)/\(sourceId)")
    }

    func markWatched(releaseId: Int, sourceId: Int, position: Int, watched: Bool = true) async throws -> CodeEnvelopeResponse {
        let action = watched ? "watch" : "unwatch"
        return try await request("episode/\(action)/\(releaseId)/\(sourceId)/\(position)", method: "POST")
    }

    func parseVideo(url: String) async throws -> DirectLinksWrapper {
        struct Body: Codable { let url: String }
        return try await request("video/parse", method: "POST", body: encodeBody(Body(url: url)))
    }

    // MARK: - History

    func history(page: Int) async throws -> Pageable<Release> {
        try await request("history/\(page)")
    }

    func saveHistory(releaseId: Int, sourceId: Int, position: Int) async throws -> CodeEnvelopeResponse {
        try await request("history/add/\(releaseId)/\(sourceId)/\(position)")
    }

    func deleteHistory(releaseId: Int) async throws -> CodeEnvelopeResponse {
        try await request("history/delete/\(releaseId)")
    }

    // MARK: - Favorites & lists

    func favoriteAdd(releaseId: Int) async throws -> CodeEnvelopeResponse {
        try await request("favorite/add/\(releaseId)")
    }

    func favoriteDelete(releaseId: Int) async throws -> CodeEnvelopeResponse {
        try await request("favorite/delete/\(releaseId)")
    }

    func favorites(page: Int) async throws -> Pageable<Release> {
        try await request("favorite/all/\(page)")
    }

    func profileListAdd(status: ProfileListStatus, releaseId: Int) async throws -> CodeEnvelopeResponse {
        try await request("profile/list/add/\(status.rawValue)/\(releaseId)")
    }

    func profileListDelete(status: ProfileListStatus, releaseId: Int) async throws -> CodeEnvelopeResponse {
        try await request("profile/list/delete/\(status.rawValue)/\(releaseId)")
    }

    func profileList(status: ProfileListStatus, page: Int) async throws -> Pageable<Release> {
        try await request("profile/list/all/\(status.rawValue)/\(page)")
    }

    func profileListByProfile(profileId: Int, status: ProfileListStatus, page: Int) async throws -> Pageable<Release> {
        try await request("profile/list/all/\(profileId)/\(status.rawValue)/\(page)")
    }

    // MARK: - Votes

    func voteRelease(releaseId: Int, vote: Int) async throws -> CodeEnvelopeResponse {
        try await request("release/vote/add/\(releaseId)/\(vote)")
    }

    func voteDelete(releaseId: Int) async throws -> CodeEnvelopeResponse {
        try await request("release/vote/delete/\(releaseId)")
    }

    // MARK: - Collections

    func collection(id: Int) async throws -> CollectionWrapper {
        try await request("collection/\(id)")
    }

    func collections(page: Int) async throws -> Pageable<Collection> {
        try await request("collection/all/\(page)")
    }

    func collectionReleases(id: Int, page: Int) async throws -> Pageable<Release> {
        try await request("collection/\(id)/releases/\(page)")
    }

    func favoriteCollectionAdd(id: Int) async throws -> CodeEnvelopeResponse {
        try await request("collectionFavorite/add/\(id)")
    }

    func favoriteCollectionDelete(id: Int) async throws -> CodeEnvelopeResponse {
        try await request("collectionFavorite/delete/\(id)")
    }

    // MARK: - Comments

    func releaseComments(releaseId: Int, page: Int) async throws -> Pageable<ReleaseComment> {
        try await request("release/comment/all/\(releaseId)/\(page)")
    }

    func commentReplies(releaseId: Int, commentId: Int, page: Int) async throws -> Pageable<ReleaseComment> {
        try await request("release/comment/replies/\(commentId)/\(page)", method: "POST")
    }

    func addComment(releaseId: Int, message: String, parentCommentId: Int? = nil, replyToProfileId: Int? = nil, isSpoiler: Bool = false) async throws -> CodeEnvelopeResponse {
        struct Body: Codable {
            let message: String
            let parentCommentId: Int?
            let replyToProfileId: Int?
            let isSpoiler: Bool
        }
        return try await request("release/comment/add/\(releaseId)", method: "POST", body: encodeBody(
            Body(message: message, parentCommentId: parentCommentId, replyToProfileId: replyToProfileId, isSpoiler: isSpoiler)
        ))
    }

    func deleteComment(commentId: Int) async throws -> CodeEnvelopeResponse {
        try await request("release/comment/delete/\(commentId)")
    }

    func voteComment(commentId: Int, vote: Int) async throws -> CodeEnvelopeResponse {
        try await request("release/comment/vote/\(commentId)/\(vote)")
    }

    // MARK: - Profile & friends

    func profile(id: Int) async throws -> ProfileWrapper {
        try await request("profile/\(id)")
    }

    func friendRequestSend(id: Int) async throws -> CodeEnvelopeResponse {
        try await request("profile/friend/request/send/\(id)")
    }

    func friendRemove(id: Int) async throws -> CodeEnvelopeResponse {
        try await request("profile/friend/request/remove/\(id)")
    }

    func friends(id: Int, page: Int) async throws -> Pageable<Profile> {
        try await request("profile/friend/all/\(id)/\(page)")
    }

    func blocklistAdd(id: Int) async throws -> CodeEnvelopeResponse {
        try await request("profile/blocklist/add/\(id)")
    }

    func blocklistRemove(id: Int) async throws -> CodeEnvelopeResponse {
        try await request("profile/blocklist/remove/\(id)")
    }

    // MARK: - Notifications

    func notificationCount() async throws -> NotificationCount {
        try await request("notification/count")
    }

    func notificationEpisodes(page: Int) async throws -> Pageable<ProfileEpisodeNotification> {
        try await request("notification/episodes/\(page)")
    }

    func notificationComments(page: Int) async throws -> Pageable<ReleaseComment> {
        try await request("notification/releaseComments/\(page)")
    }

    func markNotificationsRead() async throws -> CodeEnvelopeResponse {
        try await request("notification/read")
    }
}

// MARK: - Response wrappers

struct CodeEnvelopeResponse: Codable {
    let code: Int?
}

struct ReleaseWrapper: Codable {
    let code: Int?
    let release: Release?
}

struct EpisodeTypesWrapper: Codable {
    let code: Int?
    let types: [EpisodeType]?
}

struct EpisodeSourcesWrapper: Codable {
    let code: Int?
    let sources: [EpisodeSource]?
}

struct EpisodesWrapper: Codable {
    let code: Int?
    let episodes: [Episode]?
}

struct DirectLinksWrapper: Codable {
    let code: Int?
    let `default`: DirectLinks?

    enum CodingKeys: String, CodingKey {
        case code
        case `default` = "default"
    }
}

struct CollectionWrapper: Codable {
    let code: Int?
    let collection: Collection?
}

struct ProfileWrapper: Codable {
    let code: Int?
    let profile: Profile?
    let isMyProfile: Bool?

    enum CodingKeys: String, CodingKey {
        case code, profile
        case isMyProfile = "is_my_profile"
    }
}
