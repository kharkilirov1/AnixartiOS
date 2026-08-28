import SwiftUI

@main
struct AnixartApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(Theme.carmine)
        }
    }
}

// MARK: - App state

@Observable
final class AppState {
    var isLoggedIn: Bool = TokenStore.load() != nil
    var isGuest: Bool = UserDefaults.standard.bool(forKey: "isGuest")
    var myProfileId: Int = UserDefaults.standard.integer(forKey: "myProfileId")
    var myProfile: Profile?
    var pendingDeepLink: DeepLink?

    var isAuthorized: Bool { isLoggedIn || isGuest }

    func didSignIn(token: String, profile: Profile?) {
        TokenStore.save(token)
        isLoggedIn = true
        isGuest = false
        UserDefaults.standard.set(false, forKey: "isGuest")
        if let profile {
            myProfile = profile
            myProfileId = profile.id
            UserDefaults.standard.set(profile.id, forKey: "myProfileId")
        }
    }

    func continueAsGuest() {
        isGuest = true
        UserDefaults.standard.set(true, forKey: "isGuest")
    }

    func signOut() {
        TokenStore.clear()
        isLoggedIn = false
        isGuest = false
        myProfile = nil
        myProfileId = 0
        UserDefaults.standard.removeObject(forKey: "isGuest")
        UserDefaults.standard.removeObject(forKey: "myProfileId")
    }
}

// MARK: - Deep links (anixart://release/123 etc.)

enum DeepLink: Equatable {
    case release(Int)
    case collection(Int)
    case profile(Int)

    static func parse(_ url: URL) -> DeepLink? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2, let id = Int(parts[1]) else { return nil }
        switch parts[0] {
        case "release": return .release(id)
        case "collection": return .collection(id)
        case "profile": return .profile(id)
        default: return nil
        }
    }
}

/// Wrapper for deep-link navigation values (release/collection by id).
enum DeepLinkDest: Hashable {
    case release(Int)
    case collection(Int)
}

// MARK: - Shared navigation destinations

struct AppDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Release.self) { release in
                ReleaseView(releaseId: release.id, placeholder: release)
            }
            .navigationDestination(for: Int.self) { profileId in
                ProfileView(profileId: profileId)
            }
            .navigationDestination(for: Collection.self) { collection in
                CollectionDetailView(collectionId: collection.id, placeholder: collection)
            }
            .navigationDestination(for: PlayerContext.self) { context in
                PlayerView(context: context)
            }
            .navigationDestination(for: DeepLinkDest.self) { dest in
                switch dest {
                case .release(let id):
                    ReleaseView(releaseId: id, placeholder: nil)
                case .collection(let id):
                    CollectionDetailView(collectionId: id, placeholder: nil)
                }
            }
    }
}

// MARK: - Root

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthorized {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.isAuthorized)
        .onOpenURL { url in
            if let link = DeepLink.parse(url) {
                appState.pendingDeepLink = link
            }
        }
    }
}

// MARK: - Main tabs

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var searchPath = NavigationPath()
    @State private var catalogPath = NavigationPath()
    @State private var bookmarksPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $searchPath) {
                HomeView()
                    .modifier(AppDestinations())
            }
            .tabItem { Label("Главная", systemImage: "house.fill") }
            .tag(0)

            NavigationStack(path: $catalogPath) {
                CatalogView()
                    .modifier(AppDestinations())
            }
            .tabItem { Label("Каталог", systemImage: "square.grid.2x2.fill") }
            .tag(1)

            NavigationStack {
                SearchView()
                    .modifier(AppDestinations())
            }
            .tabItem { Label("Поиск", systemImage: "magnifyingglass") }
            .tag(2)

            NavigationStack(path: $bookmarksPath) {
                BookmarksView()
                    .modifier(AppDestinations())
            }
            .tabItem { Label("Закладки", systemImage: "bookmark.fill") }
            .tag(3)

            NavigationStack(path: $profilePath) {
                ProfileView(profileId: appState.myProfileId)
                    .modifier(AppDestinations())
            }
            .tabItem { Label("Профиль", systemImage: "person.fill") }
            .tag(4)
        }
        .onChange(of: appState.pendingDeepLink) { _, link in
            guard let link else { return }
            switch link {
            case .release(let id):
                searchPath.append(DeepLinkDest.release(id))
            case .collection(let id):
                searchPath.append(DeepLinkDest.collection(id))
            case .profile(let id):
                searchPath.append(id)
            }
            appState.pendingDeepLink = nil
        }
    }
}
