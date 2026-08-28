import SwiftUI
import AVKit
import WebKit

// MARK: - Player screen: routes between native AVPlayer and WebView (iframe)

struct PlayerView: View {
    let context: PlayerContext

    @State private var links: DirectLinks?
    @State private var loading = true
    @State private var mode: Mode?
    @State private var error: String?
    @State private var watchedNotified = false

    enum Mode {
        case native(URL)
        case web(URL)
    }

    var body: some View {
        VStack(spacing: 0) {
            if loading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ErrorView(message: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let mode {
                switch mode {
                case .native(let url):
                    NativePlayerView(url: url, title: context.episode.name ?? "Серия \(context.episode.position ?? 0)")
                case .web(let url):
                    WebPlayerView(url: url)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(context.episode.name ?? "Серия \(context.episode.position ?? 0)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await resolve() }
        .onDisappear {
            Task { await markWatched() }
        }
    }

    private func resolve() async {
        loading = true
        error = nil
        defer { loading = false }

        guard let raw = context.episode.url else {
            error = "Ссылка на эпизод отсутствует"
            return
        }

        if context.episode.iframe == true {
            // Kodik and other embeds go through the WebView player.
            if let url = URL(string: raw) {
                mode = .web(url)
                await markWatched()
                return
            }
            error = "Некорректная ссылка плеера"
            return
        }

        // Direct link: ask the server to resolve qualities (video/parse).
        do {
            let resp = try await APIClient.shared.parseVideo(url: raw)
            links = resp.default
            let candidates: [(String, String?)] = [
                ("1080p", resp.default?.q1080p),
                ("720p", resp.default?.q720p),
                ("480p", resp.default?.q480p),
                ("360p", resp.default?.q360p),
                ("default", resp.default?.default),
            ]
            if let best = candidates.first(where: { $0.1 != nil })?.1, let url = URL(string: best) {
                mode = .native(url)
                await markWatched()
            } else if let url = URL(string: raw) {
                mode = .native(url)
                await markWatched()
            } else {
                error = "Не удалось получить видеопоток"
            }
        } catch {
            // Fallback: try the raw URL directly.
            if let url = URL(string: raw) {
                mode = .native(url)
                await markWatched()
            } else {
                self.error = error.localizedDescription
            }
        }
    }

    private func markWatched() async {
        guard !watchedNotified else { return }
        watchedNotified = true
        _ = try? await APIClient.shared.markWatched(
            releaseId: context.releaseId,
            sourceId: context.sourceId,
            position: context.episode.position ?? 0
        )
        _ = try? await APIClient.shared.saveHistory(
            releaseId: context.releaseId,
            sourceId: context.sourceId,
            position: context.episode.position ?? 0
        )
    }
}

// MARK: - Native AVPlayer

struct NativePlayerView: View {
    let url: URL
    let title: String
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 0) {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .bottom)
                    .onAppear { player.play() }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.black)
        .onAppear {
            if player == nil {
                let p = AVPlayer(url: url)
                player = p
                p.play()
            }
        }
        .onDisappear {
            player?.pause()
        }
    }
}

// MARK: - WebView player (Kodik etc.)

struct WebPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.backgroundColor = .black
        web.isOpaque = false
        web.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}
}
