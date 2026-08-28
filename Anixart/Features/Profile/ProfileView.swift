import SwiftUI
import Kingfisher

// MARK: - Profile

enum ProfileSubRoute: Hashable {
    case friends(Int)
    case notifications
}

struct ProfileView: View {
    let profileId: Int

    @Environment(AppState.self) private var appState
    @State private var profile: Profile?
    @State private var isMyProfile = false
    @State private var error: String?
    @State private var selectedList: ProfileListStatus = .watching
    @State private var listReleases: [Release] = []
    @State private var listLoading = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if appState.isGuest && profileId == 0 {
                    guestPlaceholder
                } else if let profile {
                    header(profile)
                    counters(profile)
                    if isMyProfile {
                        myActions
                    } else {
                        otherActions(profile)
                    }
                    listsSection(profile)
                } else if let error {
                    ErrorView(message: error) { Task { await load() } }
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .navigationTitle(profile?.login ?? "Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var guestPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 44))
                .foregroundStyle(Theme.inkTertiary)
            Text("Вы вошли как гость")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.inkPrimary)
            Text("Войдите в аккаунт, чтобы видеть профиль, закладки и уведомления")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            Button {
                appState.signOut()
            } label: {
                Text("Войти в аккаунт")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.carmine)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }

    private func header(_ p: Profile) -> some View {
        VStack(spacing: 10) {
            KFImage(URL(string: p.avatar ?? ""))
                .placeholder { Circle().fill(Theme.tertiary) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.carmine.opacity(0.5), lineWidth: 2))

            Text(p.login ?? "")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.inkPrimary)

            HStack(spacing: 8) {
                ForEach(p.roles ?? []) { role in
                    Text(role.name ?? "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(role.color.map { Color(hexString: $0) } ?? Theme.inkSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((role.color.map { Color(hexString: $0) } ?? Theme.inkSecondary).opacity(0.12))
                        .clipShape(Capsule())
                }
                if p.isSponsor == true {
                    Text("SPONSOR")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.yellow.opacity(0.12))
                        .clipShape(Capsule())
                }
                if p.isOnline == true {
                    Circle().fill(.green).frame(width: 8, height: 8)
                }
            }

            if let status = p.status, !status.isEmpty {
                Text(status)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func counters(_ p: Profile) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 12) {
            statCell(p.watchingCount ?? 0, "Смотрят", .watching)
            statCell(p.planCount ?? 0, "В планах", .plans)
            statCell(p.completedCount ?? 0, "Просмотрено", .completed)
            statCell(p.holdOnCount ?? 0, "Отложено", .holdOn)
            statCell(p.droppedCount ?? 0, "Брошено", .dropped)
            statCell(p.favoriteCount ?? 0, "Избранное", nil)
            statCell(p.collectionCount ?? 0, "Коллекций", nil)
            statCell(p.friendCount ?? 0, "Друзей", nil)
        }
        .padding(.horizontal, 16)
    }

    private func statCell(_ value: Int, _ label: String, _ status: ProfileListStatus?) -> some View {
        Group {
            if let status {
                Button {
                    selectedList = status
                    Task { await loadList(status) }
                } label: {
                    statBody(value, label)
                }
                .buttonStyle(.plain)
            } else {
                statBody(value, label)
            }
        }
    }

    private func statBody(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.inkPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var myActions: some View {
        HStack(spacing: 10) {
            NavigationLink(value: ProfileSubRoute.friends(profileId)) {
                Label("Друзья", systemImage: "person.2")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(Theme.inkPrimary)
                    .background(Theme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            NavigationLink(value: ProfileSubRoute.notifications) {
                Label("Уведомления", systemImage: "bell")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(Theme.inkPrimary)
                    .background(Theme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button {
                appState.signOut()
            } label: {
                Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(Theme.carmine)
                    .background(Theme.carmine.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .navigationDestination(for: ProfileSubRoute.self) { route in
            switch route {
            case .friends(let id):
                FriendsListView(profileId: id)
            case .notifications:
                NotificationsView()
            }
        }
    }

    private func otherActions(_ p: Profile) -> some View {
        HStack(spacing: 10) {
            Button {
                Task { await toggleFriend(p) }
            } label: {
                Label(friendButtonTitle(p), systemImage: "person.badge.plus")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(Theme.inkPrimary)
                    .background(Theme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Menu {
                Button("В чёрный список", role: .destructive) {
                    Task { _ = try? await APIClient.shared.blocklistAdd(id: p.id) }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.inkPrimary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Theme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
    }

    private func friendButtonTitle(_ p: Profile) -> String {
        switch p.friendStatus {
        case 1: return "Удалить из друзей"
        case 2: return "Заявка отправлена"
        case 3: return "Принять заявку"
        default: return "Добавить в друзья"
        }
    }

    private func listsSection(_ p: Profile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ProfileListStatus.allCases) { status in
                        Chip(text: status.title, selected: selectedList == status) {
                            selectedList = status
                            Task { await loadList(status) }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            if listLoading && listReleases.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if listReleases.isEmpty {
                EmptyStateView(text: "Список пуст")
            } else {
                ReleaseGrid(releases: listReleases)
            }
        }
    }

    private func load() async {
        error = nil
        do {
            let resp = try await APIClient.shared.profile(id: profileId)
            if let p = resp.profile {
                profile = p
                isMyProfile = resp.isMyProfile ?? (p.id == appState.myProfileId)
                await loadList(.watching)
            } else {
                error = "Профиль недоступен (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadList(_ status: ProfileListStatus) async {
        listLoading = true
        defer { listLoading = false }
        do {
            let resp: Pageable<Release>
            if isMyProfile {
                resp = try await APIClient.shared.profileList(status: status, page: 0)
            } else {
                resp = try await filterByList(status)
            }
            listReleases = resp.content ?? []
        } catch {
            listReleases = []
        }
    }

    private func filterByList(_ status: ProfileListStatus) async throws -> Pageable<Release> {
        // profile/list/all/{p_id}/{status}/{page}
        try await APIClient.shared.profileListByProfile(profileId: profileId, status: status, page: 0)
    }

    private func toggleFriend(_ p: Profile) async {
        _ = try? await APIClient.shared.friendRequestSend(id: p.id)
        await load()
    }
}

// MARK: - Profile row (search results)

struct ProfileRow: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: profile.avatar ?? ""))
                .placeholder { Circle().fill(Theme.tertiary) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.login ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.inkPrimary)
                if let status = profile.status, !status.isEmpty {
                    Text(status)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Friends list

struct FriendsListView: View {
    let profileId: Int
    @State private var friends: [Profile] = []
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if friends.isEmpty && error == nil {
                    ProgressView().padding(.top, 40)
                } else if let error {
                    ErrorView(message: error) { Task { await load() } }
                } else if friends.isEmpty {
                    EmptyStateView(text: "Список друзей пуст")
                } else {
                    ForEach(friends) { friend in
                        NavigationLink(value: friend.id) {
                            ProfileRow(profile: friend)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .navigationTitle("Друзья")
        .task { await load() }
    }

    private func load() async {
        do {
            let resp = try await APIClient.shared.friends(id: profileId, page: 0)
            friends = resp.content ?? []
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Notifications

struct NotificationsView: View {
    @State private var feed = 0
    @State private var episodes: [ProfileEpisodeNotification] = []
    @State private var comments: [ReleaseComment] = []
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $feed) {
                Text("Эпизоды").tag(0)
                Text("Комментарии").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(16)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if loading && episodes.isEmpty && comments.isEmpty {
                        ProgressView().padding(.top, 30)
                    } else if feed == 0 {
                        if episodes.isEmpty {
                            EmptyStateView(text: "Нет уведомлений")
                        } else {
                            ForEach(episodes) { notif in
                                episodeCell(notif)
                            }
                        }
                    } else {
                        if comments.isEmpty {
                            EmptyStateView(text: "Нет уведомлений")
                        } else {
                            ForEach(comments) { comment in
                                commentCell(comment)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Theme.bg)
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Прочитать всё") {
                    Task { _ = try? await APIClient.shared.markNotificationsRead() }
                }
                .font(.system(size: 13))
            }
        }
        .task { await load() }
        .onChange(of: feed) { _, _ in Task { await load() } }
    }

    private func episodeCell(_ notif: ProfileEpisodeNotification) -> some View {
        NavigationLink(value: DeepLinkDest.release(notif.release?.id ?? 0)) {
            HStack(spacing: 12) {
                KFImage(URL(string: notif.release?.image ?? ""))
                    .placeholder { Rectangle().fill(Theme.tertiary) }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 3) {
                    Text(notif.release?.titleRu ?? "")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.inkPrimary)
                        .lineLimit(2)
                    Text("Новый эпизод: \(notif.episode?.name ?? "—")")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.carmine)
                }
                Spacer()
                Image(systemName: "play.circle")
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(10)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func commentCell(_ comment: ReleaseComment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.profile?.login ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                Image(systemName: "bubble.left")
                    .foregroundStyle(Theme.inkTertiary)
            }
            Text(comment.message ?? "")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSecondary)
                .lineLimit(3)
        }
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            if feed == 0 {
                let resp = try await APIClient.shared.notificationEpisodes(page: 0)
                episodes = resp.content ?? []
            } else {
                let resp = try await APIClient.shared.notificationComments(page: 0)
                comments = resp.content ?? []
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
