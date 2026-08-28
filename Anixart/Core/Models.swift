import Foundation

// MARK: - Envelope

struct Pageable<T: Codable & Sendable>: Codable {
    let code: Int?
    let content: [T]?
    let currentPage: Int?
    let totalCount: Int?
    let totalPageCount: Int?

    enum CodingKeys: String, CodingKey {
        case code, content
        case currentPage = "current_page"
        case totalCount = "total_count"
        case totalPageCount = "total_page_count"
    }
}

// MARK: - Reference types

struct RefEntity: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
}

struct ReleaseStatusRef: Codable, Hashable {
    let id: Int?
    let name: String?
}

// MARK: - Release

struct Release: Codable, Identifiable, Hashable {
    let id: Int
    let titleRu: String?
    let titleOriginal: String?
    let titleAlt: String?
    let description: String?
    let poster: String?
    let image: String?
    let screenshots: [String]?
    let screenshotImages: [String]?
    let year: String?
    let season: Int?
    let source: String?
    let status: ReleaseStatusRef?
    let statusId: Int?
    let category: RefEntity?
    let genres: String?
    let country: String?
    let studio: String?
    let director: String?
    let author: String?
    let translators: String?
    let ageRating: Int?
    let broadcast: Int?
    let duration: Int?
    let episodesTotal: Int?
    let episodesReleased: Int?
    let grade: Double?
    let rating: Int?
    let voteCount: Int?
    let vote1Count: Int?
    let vote2Count: Int?
    let vote3Count: Int?
    let vote4Count: Int?
    let vote5Count: Int?
    let yourVote: Int?
    let favoriteCount: Int?
    let watchingCount: Int?
    let completedCount: Int?
    let droppedCount: Int?
    let holdOnCount: Int?
    let planCount: Int?
    let collectionCount: Int?
    let commentCount: Int?
    let relatedCount: Int?
    let relatedReleases: [Release]?
    let recommendedReleases: [Release]?
    var isFavorite: Bool?
    let isViewed: Bool?
    let isAdult: Bool?
    let isDeleted: Bool?
    let isViewBlocked: Bool?
    let isPlayDisabled: Bool?
    let canTorlookSearch: Bool?
    let canVideoAppeal: Bool?
    var profileListStatus: Int?
    let lastViewEpisode: Episode?
    let lastViewTimestamp: Int?
    let episodeLastUpdate: EpisodeUpdate?
    let videoBanners: [VideoBanner]?
    let note: String?
    let airedOnDate: Int?
    let releaseDate: Int?
    let lastUpdateDate: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case titleRu = "title_ru"
        case titleOriginal = "title_original"
        case titleAlt = "title_alt"
        case description
        case poster, image
        case screenshots
        case screenshotImages = "screenshot_images"
        case year, season, source, status, category, genres, country, studio, director, author, translators
        case ageRating = "age_rating"
        case broadcast, duration
        case episodesTotal = "episodes_total"
        case episodesReleased = "episodes_released"
        case grade, rating
        case voteCount = "vote_count"
        case vote1Count = "vote_1_count"
        case vote2Count = "vote_2_count"
        case vote3Count = "vote_3_count"
        case vote4Count = "vote_4_count"
        case vote5Count = "vote_5_count"
        case yourVote = "your_vote"
        case favoriteCount = "favorites_count"
        case watchingCount = "watching_count"
        case completedCount = "completed_count"
        case droppedCount = "dropped_count"
        case holdOnCount = "hold_on_count"
        case planCount = "plan_count"
        case collectionCount = "collection_count"
        case commentCount = "comment_count"
        case relatedCount = "related_count"
        case relatedReleases = "related_releases"
        case recommendedReleases = "recommended_releases"
        case isFavorite = "is_favorite"
        case isViewed = "is_viewed"
        case isAdult = "is_adult"
        case isDeleted = "is_deleted"
        case isViewBlocked = "is_view_blocked"
        case isPlayDisabled = "is_play_disabled"
        case canTorlookSearch = "can_torlook_search"
        case canVideoAppeal = "can_video_appeal"
        case profileListStatus = "profile_list_status"
        case lastViewEpisode = "last_view_episode"
        case lastViewTimestamp = "last_view_timestamp"
        case episodeLastUpdate = "episode_last_update"
        case videoBanners = "video_banners"
        case note
        case airedOnDate = "aired_on_date"
        case releaseDate = "release_date"
        case lastUpdateDate = "last_update_date"
        case statusId = "status_id"
    }

    var genreList: [String] {
        (genres ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var ageRatingLabel: String? {
        switch ageRating {
        case 1: return "13-"
        case 2: return "13+"
        case 3: return "26+"  // 18+ semantics per app
        case 4: return "100+"
        default: return nil
        }
    }

    var statusLabel: String {
        switch statusId {
        case 1: return "Вышел"
        case 2: return "Выходит"
        case 3: return "Анонс"
        case 4: return "Заморожен"
        case 5: return "Отменён"
        default: return status?.name ?? ""
        }
    }

    var isOngoing: Bool { statusId == 2 }
}

struct VideoBanner: Codable, Hashable, Identifiable {
    var id: String { name ?? UUID().uuidString }
    let name: String?
    let image: String?
    let value: String?
    let actionId: Int?
    let isNew: Bool?

    enum CodingKeys: String, CodingKey {
        case name, image, value
        case actionId = "action_id"
        case isNew = "is_new"
    }
}

struct EpisodeUpdate: Codable, Hashable {
    let lastEpisodeUpdateDate: Int?
    let lastEpisodeUpdateName: String?
    let lastEpisodeSourceUpdateId: Int?
    let lastEpisodeSourceUpdateName: String?
    let lastEpisodeTypeUpdateId: Int?
    let lastEpisodeTypeUpdateName: String?

    enum CodingKeys: String, CodingKey {
        case lastEpisodeUpdateDate = "last_episode_update_date"
        case lastEpisodeUpdateName = "last_episode_update_name"
        case lastEpisodeSourceUpdateId = "last_episode_source_update_id"
        case lastEpisodeSourceUpdateName = "last_episode_source_update_name"
        case lastEpisodeTypeUpdateId = "last_episode_type_update_id"
        case lastEpisodeTypeUpdateName = "lastEpisodeTypeUpdateName"
    }
}

// MARK: - Episodes (Type = voiceover -> Source -> Episode)

struct EpisodeType: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let icon: String?
    let workers: String?
    let isSub: Bool?
    let channelId: String?
    let episodesCount: Int?
    let viewCount: Int?
    let pinned: Bool?
    let quality: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, icon, workers, pinned, quality
        case isSub = "is_sub"
        case channelId = "channel_id"
        case episodesCount = "episodes_count"
        case viewCount = "view_count"
    }
}

struct EpisodeSource: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let episodesCount: Int?
    let quality: Int?
    let type: EpisodeType?

    enum CodingKeys: String, CodingKey {
        case id, name, type, quality
        case episodesCount = "episodes_count"
    }
}

struct Episode: Codable, Identifiable, Hashable {
    var id: Int { position ?? 0 }
    let releaseId: Int?
    let sourceId: Int?
    let position: Int?
    let name: String?
    let url: String?
    let iframe: Bool?
    let isFiller: Bool?
    let isWatched: Bool?
    let playbackPosition: Int?
    let addedDate: Int?
    let quality: Int?

    // NOTE: the wire format also includes a nested `release` object here,
    // but keeping it would create a Release <-> Episode value-type cycle
    // (Optional stores inline) -> "infinite size". Intentionally not decoded.

    enum CodingKeys: String, CodingKey {
        case releaseId = "releaseId"
        case sourceId = "sourceId"
        case position, name, url, iframe, quality
        case isFiller = "is_filler"
        case isWatched = "is_watched"
        case playbackPosition = "playback_position"
        case addedDate = "addedDate"
    }
}

struct DirectLinks: Codable, Hashable {
    let `default`: String?
    let q360p: String?
    let q480p: String?
    let q720p: String?
    let q1080p: String?
}

// MARK: - Profile

struct Profile: Codable, Identifiable, Hashable {
    let id: Int
    let login: String?
    let avatar: String?
    let status: String?
    let badge: String?
    let roles: [Role]?
    let privilegeLevel: Int?
    let friendStatus: Int?
    let isOnline: Bool?
    let isVerified: Bool?
    let isSponsor: Bool?
    let isBanned: Bool?
    let isBlocked: Bool?
    let isMeBlocked: Bool?
    let isLoginChanged: Bool?
    let isGoogleBound: Bool?
    let isVkBound: Bool?
    let isSocial: Bool?
    let isCountsHidden: Bool?
    let isStatsHidden: Bool?
    let isFriendRequestsDisallowed: Bool?
    let lastActivityTime: Int?
    let registerDate: Int?
    let watchDynamics: [WatchDynamics]?
    let collectionCount: Int?
    let commentCount: Int?
    let completedCount: Int?
    let droppedCount: Int?
    let favoriteCount: Int?
    let friendCount: Int?
    let holdOnCount: Int?
    let planCount: Int?
    let watchingCount: Int?
    let videoCount: Int?
    let watchedEpisodeCount: Int?
    let watchedTime: Int?
    let ratingScore: Int?
    let vkPage: String?
    let tgPage: String?
    let instPage: String?
    let ttPage: String?
    let discordPage: String?
    let banExpires: Int?
    let banReason: String?

    enum CodingKeys: String, CodingKey {
        case id, login, avatar, status, badge, roles
        case privilegeLevel = "privilege_level"
        case friendStatus = "friend_status"
        case isOnline = "is_online"
        case isVerified = "is_verified"
        case isSponsor = "is_sponsor"
        case isBanned = "is_banned"
        case isBlocked = "is_blocked"
        case isMeBlocked = "is_me_blocked"
        case isLoginChanged = "is_login_changed"
        case isGoogleBound = "is_google_bound"
        case isVkBound = "is_vk_bound"
        case isSocial = "is_social"
        case isCountsHidden = "is_counts_hidden"
        case isStatsHidden = "is_stats_hidden"
        case isFriendRequestsDisallowed = "is_friend_requests_disallowed"
        case lastActivityTime = "last_activity_time"
        case registerDate = "register_date"
        case watchDynamics = "watch_dynamics"
        case collectionCount = "collection_count"
        case commentCount = "comment_count"
        case completedCount = "completed_count"
        case droppedCount = "dropped_count"
        case favoriteCount = "favorite_count"
        case friendCount = "friend_count"
        case holdOnCount = "hold_on_count"
        case planCount = "plan_count"
        case watchingCount = "watching_count"
        case videoCount = "video_count"
        case watchedEpisodeCount = "watched_episode_count"
        case watchedTime = "watched_time"
        case ratingScore = "rating_score"
        case vkPage = "vk_page"
        case tgPage = "tg_page"
        case instPage = "inst_page"
        case ttPage = "tt_page"
        case discordPage = "discord_page"
        case banExpires = "ban_expires"
        case banReason = "ban_reason"
    }

    var roleColorHex: String? { roles?.first?.color }
}

struct Role: Codable, Hashable {
    let id: Int?
    let name: String?
    let color: String?
}

struct WatchDynamics: Codable, Hashable {
    let count: Int?
    let day: Int?
    let timestamp: Int?
}

struct ProfileToken: Codable {
    let id: Int?
    let token: String?
}

// MARK: - Auth

struct SignInResponse: Codable {
    let code: Int?
    let profile: Profile?
    let profileToken: ProfileToken?
}

struct SignUpResponse: Codable {
    let code: Int?
    let hash: String?
    let codeTimestampExpires: Int?
}

// MARK: - Collection

struct Collection: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let description: String?
    let image: String?
    let creator: Profile?
    let isPrivate: Bool?
    var isFavorite: Bool?
    let isDeleted: Bool?
    let favoriteCount: Int?
    let commentCount: Int?
    let creationDate: Int?
    let lastUpdateDate: Int?
    let releases: [Release]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, creator, releases
        case isPrivate = "is_private"
        case isFavorite = "is_favorite"
        case isDeleted = "is_deleted"
        case favoriteCount = "favorites_count"
        case commentCount = "comment_count"
        case creationDate = "creation_date"
        case lastUpdateDate = "last_update_date"
    }
}

// MARK: - Comments

struct ReleaseComment: Codable, Identifiable, Hashable {
    let id: Int
    let message: String?
    let profile: Profile?
    let parentCommentId: Int?
    let replyCount: Int?
    let timestamp: Int?
    let vote: Int?
    let voteCount: Int?
    let isEdited: Bool?
    let isDeleted: Bool?
    let isSpoiler: Bool?

    enum CodingKeys: String, CodingKey {
        case id, message, profile, timestamp, vote
        case parentCommentId = "parentCommentId"
        case replyCount = "replyCount"
        case voteCount = "voteCount"
        case isEdited = "isEdited"
        case isDeleted = "isDeleted"
        case isSpoiler = "isSpoiler"
    }
}

// MARK: - Schedule

struct ScheduleResponse: Codable {
    let monday: [Release]?
    let tuesday: [Release]?
    let wednesday: [Release]?
    let thursday: [Release]?
    let friday: [Release]?
    let saturday: [Release]?
    let sunday: [Release]?
}

// MARK: - Search

struct SearchRequestDTO: Codable {
    var query: String
    var searchBy: Int = 0
}

// MARK: - Filter

struct FilterRequestDTO: Codable, Hashable {
    var categoryId: Int?
    var country: String?
    var endYear: Int?
    var episodeDurationFrom: Int?
    var episodeDurationTo: Int?
    var episodesFrom: Int?
    var episodesTo: Int?
    var isGenresExcludeModeEnabled: Bool?
    var season: String?
    var source: String?
    var startYear: Int?
    var statusId: Int?
    var studio: String?
    var sort: Int?
    var genres: [String]?
    var profileListExclusions: [Int]?
    var types: [Int]?
    var ageRatings: [Int]?

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case country, season, source, studio, sort, genres, types
        case endYear = "end_year"
        case episodeDurationFrom = "episode_duration_from"
        case episodeDurationTo = "episode_duration_to"
        case episodesFrom = "episodes_from"
        case episodesTo = "episodes_to"
        case isGenresExcludeModeEnabled = "is_genres_exclude_mode_enabled"
        case startYear = "start_year"
        case statusId = "status_id"
        case profileListExclusions = "profile_list_exclusions"
        case ageRatings = "age_ratings"
    }
}

// MARK: - Notifications

struct NotificationCount: Codable {
    let code: Int?
    let count: Int?
}

struct ProfileEpisodeNotification: Codable, Identifiable {
    var id: Int { episode?.position ?? 0 }
    let episode: Episode?
    let release: Release?
}

// MARK: - Toggles (runtime config)

struct Toggles: Codable {
    let baseUrl: String?
    let apiUrl: String?
    let apiAltUrl: String?
    let apiAltAvailable: Bool?
    let kodikVideoLinksUrl: String?
    let torlookUrl: String?
    let iframeEmbedUrl: String?
    let kodikIframeAd: String?
    let kodikAdIframeUrl: String?
    let sibnetUserAgent: String?
    let sibnetRandUserAgent: String?
    let editorUrl: String?
    let staticDomain: String?
    let searchBarIconUrl: String?
    let impMessageEnabled: Bool?
    let impMessageText: String?
    let impMessageLink: String?
    let sponsorshipAvailable: Bool?
    let googleAuthAvailable: Bool?
    let vkAuthAvailable: Bool?
    let telegramAuthAvailable: Bool?
    let yandexAuthAvailable: Bool?
}

// MARK: - Torlook

struct TorlookResult: Codable, Identifiable, Hashable {
    var id: String { link ?? magnetLink ?? UUID().uuidString }
    let title: String?
    let link: String?
    let size: String?
    let date: String?
    let trackerDomain: String?
    let trackerIcon: String?
    let seedCount: Int?
    let leechCount: Int?
    let magnetLink: String?
}

// MARK: - Profile list statuses (verified from BookmarksTabUiLogic)

enum ProfileListStatus: Int, CaseIterable, Identifiable {
    case watching = 1
    case plans = 2
    case completed = 3
    case holdOn = 4
    case dropped = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .watching: return "Смотрю"
        case .plans: return "В планах"
        case .completed: return "Просмотрено"
        case .holdOn: return "Отложено"
        case .dropped: return "Брошено"
        }
    }
}
