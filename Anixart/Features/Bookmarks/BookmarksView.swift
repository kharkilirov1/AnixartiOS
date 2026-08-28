import SwiftUI
import Kingfisher

// MARK: - Bookmarks (favorites / history / lists / collections)

enum BookmarksTab: String, CaseIterable, Identifiable {
    case favorites = "Избранное"
    case history = "История"
    case watching = "Смотрю"
    case completed = "Просмотрено"
    case holdOn = "Отложено"
    case dropped = "Брошено"
    case plans = "В планах"
    case collections = "Коллекции"

    var id: String { rawValue }
}

struct BookmarksView: View {
    @Environment(AppState.self) private var appState
    @State private var tab: BookmarksTab = .favorites

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BookmarksTab.allCases) { t in
                        Chip(text: t.rawValue, selected: tab == t) { tab = t }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            if appState.isGuest {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.inkTertiary)
                    Text("Закладки доступны после входа в аккаунт")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .background(Theme.bg)
        .navigationTitle("Закладки")
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .favorites:
            ReleasePagedFeed { page in
                try await APIClient.shared.favorites(page: page)
            }
        case .history:
            ReleasePagedFeed { page in
                try await APIClient.shared.history(page: page)
            }
        case .watching:
            ReleasePagedFeed { page in
                try await APIClient.shared.profileList(status: .watching, page: page)
            }
        case .completed:
            ReleasePagedFeed { page in
                try await APIClient.shared.profileList(status: .completed, page: page)
            }
        case .holdOn:
            ReleasePagedFeed { page in
                try await APIClient.shared.profileList(status: .holdOn, page: page)
            }
        case .dropped:
            ReleasePagedFeed { page in
                try await APIClient.shared.profileList(status: .dropped, page: page)
            }
        case .plans:
            ReleasePagedFeed { page in
                try await APIClient.shared.profileList(status: .plans, page: page)
            }
        case .collections:
            CollectionsFeed()
        }
    }
}

// MARK: - Generic paged release feed

struct ReleasePagedFeed: View {
    var loader: (Int) async throws -> Pageable<Release>

    @State private var releases: [Release] = []
    @State private var page = 0
    @State private var loading = false
    @State private var canLoadMore = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if releases.isEmpty && loading {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 10)], spacing: 14) {
                        ForEach(0..<9, id: \.self) { _ in SkeletonCard(width: 130) }
                    }
                } else if let error, releases.isEmpty {
                    ErrorView(message: error) { Task { await load(reset: true) } }
                } else if releases.isEmpty {
                    EmptyStateView(text: "Здесь пока пусто")
                } else {
                    ReleaseGrid(releases: releases)
                    if canLoadMore {
                        Button {
                            Task { await load(reset: false) }
                        } label: {
                            HStack {
                                if loading { ProgressView().tint(Theme.inkSecondary) }
                                Text("Показать ещё")
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .refreshable { await load(reset: true) }
        .task { await load(reset: true) }
    }

    private func load(reset: Bool) async {
        if reset {
            page = 0
            canLoadMore = true
            releases = []
            error = nil
        }
        guard canLoadMore, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let resp = try await loader(page)
            let items = resp.content ?? []
            if reset { releases = items } else { releases += items }
            canLoadMore = items.count >= 20
            page += 1
        } catch {
            if releases.isEmpty { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Collections feed

struct CollectionsFeed: View {
    @State private var collections: [Collection] = []
    @State private var page = 0
    @State private var loading = false
    @State private var canLoadMore = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if collections.isEmpty && loading {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12).fill(Theme.tertiary).frame(height: 90).shimmer()
                            .padding(.horizontal, 16)
                    }
                } else if let error, collections.isEmpty {
                    ErrorView(message: error) { Task { await load(reset: true) } }
                } else if collections.isEmpty {
                    EmptyStateView(text: "Пока нет коллекций")
                } else {
                    ForEach(collections) { collection in
                        NavigationLink(value: collection) {
                            CollectionRow(collection: collection)
                        }
                        .buttonStyle(.plain)
                    }
                    if canLoadMore {
                        Button {
                            Task { await load(reset: false) }
                        } label: {
                            HStack {
                                if loading { ProgressView().tint(Theme.inkSecondary) }
                                Text("Показать ещё")
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .refreshable { await load(reset: true) }
        .task { await load(reset: true) }
    }

    private func load(reset: Bool) async {
        if reset {
            page = 0
            canLoadMore = true
            collections = []
            error = nil
        }
        guard canLoadMore, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.collections(page: page)
            let items = resp.content ?? []
            if reset { collections = items } else { collections += items }
            canLoadMore = items.count >= 20
            page += 1
        } catch {
            if collections.isEmpty { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Collection row / detail

struct CollectionRow: View {
    let collection: Collection

    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: collection.image ?? ""))
                .placeholder { Rectangle().fill(Theme.tertiary) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.inkPrimary)
                    .lineLimit(2)
                if let login = collection.creator?.login {
                    Text("от \(login)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkTertiary)
                }
                HStack(spacing: 12) {
                    Label("\(collection.favoriteCount ?? 0)", systemImage: "heart")
                    Label("\(collection.commentCount ?? 0)", systemImage: "bubble.left")
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkTertiary)
            }
            Spacer()
        }
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CollectionDetailView: View {
    let collectionId: Int
    let placeholder: Collection?

    @State private var collection: Collection?
    @State private var releases: [Release] = []
    @State private var page = 0
    @State private var canLoadMore = true
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if let collection {
                    HStack(alignment: .top, spacing: 12) {
                        KFImage(URL(string: collection.image ?? ""))
                            .placeholder { Rectangle().fill(Theme.tertiary) }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(collection.title ?? "")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.inkPrimary)
                            if let creator = collection.creator {
                                NavigationLink(value: creator.id) {
                                    Text("@\(creator.login ?? "")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.carmine)
                                }
                                .buttonStyle(.plain)
                            }
                            Button {
                                Task { await toggleFavoriteCollection(collection) }
                            } label: {
                                Label(
                                    collection.isFavorite == true ? "В избранном" : "В избранное",
                                    systemImage: collection.isFavorite == true ? "heart.fill" : "heart"
                                )
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.carmine)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    if let desc = collection.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.horizontal, 16)
                    }
                }

                if releases.isEmpty && loading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
                } else if let error, releases.isEmpty {
                    ErrorView(message: error) { Task { await load() } }
                } else {
                    ReleaseGrid(releases: releases)
                    if canLoadMore {
                        Button {
                            Task { await loadReleases(reset: false) }
                        } label: {
                            Text("Показать ещё")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.inkSecondary)
                                .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .navigationTitle(collection?.title ?? placeholder?.title ?? "Коллекция")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        error = nil
        do {
            if collection == nil {
                let resp = try await APIClient.shared.collection(id: collectionId)
                collection = resp.collection ?? placeholder
            }
            await loadReleases(reset: true)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadReleases(reset: Bool) async {
        if reset {
            page = 0
            canLoadMore = true
            releases = []
        }
        guard canLoadMore else { return }
        loading = true
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.collectionReleases(id: collectionId, page: page)
            let items = resp.content ?? []
            releases += items
            canLoadMore = items.count >= 20
            page += 1
        } catch {
            if releases.isEmpty { self.error = error.localizedDescription }
        }
    }

    private func toggleFavoriteCollection(_ c: Collection) async {
        guard var updated = collection else { return }
        do {
            if updated.isFavorite == true {
                _ = try await APIClient.shared.favoriteCollectionDelete(id: c.id)
                updated.isFavorite = false
            } else {
                _ = try await APIClient.shared.favoriteCollectionAdd(id: c.id)
                updated.isFavorite = true
            }
            collection = updated
        } catch { }
    }
}
