import SwiftUI
import Kingfisher

// MARK: - Release detail screen

struct ReleaseView: View {
    let releaseId: Int
    let placeholder: Release?

    @State private var release: Release?
    @State private var error: String?
    @State private var selectedSection = 0

    var body: some View {
        Group {
            if let release {
                content(release)
            } else if let error {
                ErrorView(message: error) { Task { await load() } }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.bg)
        .navigationTitle(release?.titleRu ?? placeholder?.titleRu ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func content(_ r: Release) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(r)
                actionButtons(r)

                Picker("", selection: $selectedSection) {
                    Text("Эпизоды").tag(0)
                    Text("Описание").tag(1)
                    Text("Комментарии").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                switch selectedSection {
                case 0:
                    EpisodesView(releaseId: r.id, totalEpisodes: r.episodesReleased ?? r.episodesTotal ?? 0)
                case 1:
                    descriptionSection(r)
                default:
                    CommentsView(releaseId: r.id)
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: Header

    private func header(_ r: Release) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                if let shot = (r.screenshots?.first ?? r.screenshotImages?.first), let shotURL = URL(string: shot) {
                    KFImage(shotURL)
                        .placeholder { Rectangle().fill(Theme.tertiary).frame(height: 200) }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .overlay(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg], startPoint: .center, endPoint: .bottom))
                }
            }
            .frame(height: 200)

            HStack(alignment: .top, spacing: 14) {
                KFImage(URL(string: r.image ?? ""))
                    .placeholder { Rectangle().fill(Theme.tertiary) }
                    .resizable()
                    .aspectRatio(2 / 3, contentMode: .fill)
                    .frame(width: 110, height: 165)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .offset(y: -60)
                    .padding(.bottom, -60)

                VStack(alignment: .leading, spacing: 6) {
                    Text(r.titleRu ?? "")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.inkPrimary)
                    if let orig = r.titleOriginal, !orig.isEmpty, orig != r.titleRu {
                        Text(orig)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkTertiary)
                    }

                    HStack(spacing: 8) {
                        if let grade = r.grade, grade > 0 { GradePill(grade: grade) }
                        Text(r.statusLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(statusColor(r))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColor(r).opacity(0.15))
                            .clipShape(Capsule())
                        if let age = r.ageRatingLabel {
                            Text(age)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Theme.carmine)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.carmine.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(metaLine(r))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
            .padding(.horizontal, 16)

            FlowLayout(spacing: 6) {
                ForEach(r.genreList, id: \.self) { genre in
                    Text(genre)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.secondary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 16) {
                statItem(count: r.watchingCount ?? 0, label: "Смотрят")
                statItem(count: r.completedCount ?? 0, label: "Просмотрено")
                statItem(count: r.planCount ?? 0, label: "В планах")
                statItem(count: r.episodesReleased ?? 0, label: "Серий")
            }
            .padding(.horizontal, 16)
        }
    }

    private func statusColor(_ r: Release) -> Color {
        switch r.statusId {
        case 1: return .green
        case 2: return Theme.carmine
        case 3: return .blue
        default: return Theme.inkSecondary
        }
    }

    private func metaLine(_ r: Release) -> String {
        var parts: [String] = []
        if let year = r.year, !year.isEmpty { parts.append(year) }
        if let cat = r.category?.name { parts.append(cat) }
        if let eps = r.episodesReleased { parts.append("\(eps) эп.") }
        if let dur = r.duration, dur > 0 { parts.append("\(dur) мин") }
        if let studio = r.studio, !studio.isEmpty { parts.append(studio) }
        return parts.joined(separator: " · ")
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.inkPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    @State private var favoriteToggle = false
    @State private var listStatusShown = false

    private func actionButtons(_ r: Release) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    Task { await toggleFavorite(r) }
                } label: {
                    Label(r.isFavorite == true ? "В избранном" : "В избранное",
                          systemImage: r.isFavorite == true ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(r.isFavorite == true ? Theme.carmine : Theme.inkPrimary)
                        .background(Theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Menu {
                    ForEach(ProfileListStatus.allCases) { status in
                        Button(status.title) {
                            Task { await setListStatus(status) }
                        }
                    }
                    if r.profileListStatus != nil {
                        Divider()
                        Button("Убрать из списка", role: .destructive) {
                            Task { await removeListStatus(r) }
                        }
                    }
                } label: {
                    Label(currentListTitle(r), systemImage: "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Theme.inkPrimary)
                        .background(Theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            VoteRow(release: r) {
                Task { await load() }
            }
        }
        .padding(.horizontal, 16)
    }

    private func currentListTitle(_ r: Release) -> String {
        if let s = r.profileListStatus, let status = ProfileListStatus(rawValue: s) {
            return status.title
        }
        return "В список"
    }

    private func descriptionSection(_ r: Release) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let desc = r.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineSpacing(3)
            }

            if let related = r.relatedReleases, !related.isEmpty {
                ReleaseRow(title: "Из той же франшизы", releases: related)
            }
            if let recommended = r.recommendedReleases, !recommended.isEmpty {
                ReleaseRow(title: "Рекомендуемое", releases: recommended)
            }

            infoRow("Тип", r.category?.name)
            infoRow("Статус", r.status?.name)
            infoRow("Год", r.year)
            infoRow("Сезон", seasonName(r.season))
            infoRow("Студия", r.studio)
            infoRow("Режиссёр", r.director)
            infoRow("Автор оригинала", r.author)
            infoRow("Страна", r.country)
            infoRow("Источники", r.source)
            if let upd = r.episodeLastUpdate?.lastEpisodeUpdateName {
                infoRow("Последнее обновление", upd)
            }
        }
        .padding(.horizontal, 16)
    }

    private func infoRow(_ label: String, _ value: String?) -> some View {
        Group {
            if let value, !value.isEmpty {
                HStack(alignment: .top) {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkTertiary)
                        .frame(width: 140, alignment: .leading)
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkPrimary)
                    Spacer()
                }
            }
        }
    }

    private func seasonName(_ season: Int?) -> String? {
        guard let season else { return nil }
        switch season {
        case 1: return "Зима"
        case 2: return "Весна"
        case 3: return "Лето"
        case 4: return "Осень"
        default: return nil
        }
    }

    // MARK: Data

    private func load() async {
        error = nil
        do {
            let resp = try await APIClient.shared.release(id: releaseId)
            if let r = resp.release {
                release = r
            } else {
                error = "Релиз недоступен (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func toggleFavorite(_ r: Release) async {
        guard var updated = release else { return }
        do {
            if updated.isFavorite == true {
                _ = try await APIClient.shared.favoriteDelete(releaseId: r.id)
                updated.isFavorite = false
            } else {
                _ = try await APIClient.shared.favoriteAdd(releaseId: r.id)
                updated.isFavorite = true
            }
            release = updated
        } catch { }
    }

    private func setListStatus(_ status: ProfileListStatus) async {
        guard var updated = release else { return }
        do {
            _ = try await APIClient.shared.profileListAdd(status: status, releaseId: updated.id)
            updated.profileListStatus = status.rawValue
            release = updated
        } catch { }
    }

    private func removeListStatus(_ r: Release) async {
        guard var updated = release,
              let current = updated.profileListStatus,
              let status = ProfileListStatus(rawValue: current) else { return }
        do {
            _ = try await APIClient.shared.profileListDelete(status: status, releaseId: updated.id)
            updated.profileListStatus = nil
            release = updated
        } catch { }
    }
}

// MARK: - Vote row (1..5 stars)

struct VoteRow: View {
    let release: Release
    var onChange: () -> Void
    @State private var voting = false

    var body: some View {
        HStack {
            Text("Оценить")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.inkPrimary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        Task { await vote(star) }
                    } label: {
                        Image(systemName: (release.yourVote ?? 0) >= star ? "star.fill" : "star")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.carmine)
                    }
                    .disabled(voting)
                }
            }
            if release.yourVote != nil && release.yourVote ?? 0 > 0 {
                Button {
                    Task { await removeVote() }
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .padding(12)
        .background(Theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func vote(_ star: Int) async {
        voting = true
        defer { voting = false }
        _ = try? await APIClient.shared.voteRelease(releaseId: release.id, vote: star)
        onChange()
    }

    private func removeVote() async {
        voting = true
        defer { voting = false }
        _ = try? await APIClient.shared.voteDelete(releaseId: release.id)
        onChange()
    }
}

// MARK: - Episodes (Type -> Source -> Episode)

struct EpisodesView: View {
    let releaseId: Int
    let totalEpisodes: Int

    @State private var types: [EpisodeType] = []
    @State private var selectedType: EpisodeType?
    @State private var sources: [EpisodeSource] = []
    @State private var selectedSource: EpisodeSource?
    @State private var episodes: [Episode] = []
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let error {
                ErrorView(message: error) { Task { await loadTypes() } }
            } else if types.isEmpty && loading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if types.isEmpty {
                EmptyStateView(text: "Эпизоды недоступны")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(types) { type in
                            typeChip(type)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if sources.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sources) { source in
                                Chip(text: "\(source.name ?? "") · \(source.episodesCount ?? 0)",
                                     selected: selectedSource?.id == source.id) {
                                    selectedSource = source
                                    Task { await loadEpisodes() }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if loading && episodes.isEmpty {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
                } else if episodes.isEmpty {
                    EmptyStateView(text: "Нет эпизодов у этого источника")
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
                        ForEach(episodes) { episode in
                            episodeCell(episode)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 4)
        .task { await loadTypes() }
    }

    private func typeChip(_ type: EpisodeType) -> some View {
        Button {
            selectedType = type
            Task { await loadSources() }
        } label: {
            HStack(spacing: 6) {
                if let icon = type.icon, let url = URL(string: icon) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(type.name ?? "")
                        .font(.system(size: 13, weight: selectedType?.id == type.id ? .semibold : .regular))
                    if let count = type.episodesCount, count > 0 {
                        Text("\(count) эп.")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
            }
            .foregroundStyle(selectedType?.id == type.id ? .white : Theme.inkSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedType?.id == type.id ? Theme.carmine : Theme.secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func episodeCell(_ episode: Episode) -> some View {
        NavigationLink(value: PlayerContext(
            releaseId: releaseId,
            releaseTitle: "",
            sourceId: episode.sourceId ?? 0,
            episode: episode,
            type: selectedType,
            source: selectedSource
        )) {
            VStack(spacing: 4) {
                Text("\(episode.position ?? 0)")
                    .font(.system(size: 16, weight: .semibold))
                if episode.isWatched == true {
                    Circle().fill(Theme.carmine).frame(width: 5, height: 5)
                } else {
                    Circle().fill(.clear).frame(width: 5, height: 5)
                }
            }
            .foregroundStyle(episode.isWatched == true ? Theme.carmine : Theme.inkPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(episode.isWatched == true ? Theme.carmine.opacity(0.12) : Theme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                if episode.isFiller == true {
                    Text("F")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.orange)
                        .padding(3)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            Task { _ = try? await APIClient.shared.saveHistory(
                releaseId: releaseId,
                sourceId: episode.sourceId ?? 0,
                position: episode.position ?? 0
            ) }
        })
    }

    private func loadTypes() async {
        error = nil
        loading = true
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.episodeTypes(releaseId: releaseId)
            types = (resp.types ?? []).sorted { ($0.pinned ?? false) && !($1.pinned ?? false) }
            if let first = types.first {
                selectedType = first
                await loadSources()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadSources() async {
        guard let type = selectedType else { return }
        loading = true
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.episodeSources(releaseId: releaseId, typeId: type.id)
            sources = resp.sources ?? []
            if sources.isEmpty {
                selectedSource = nil
                episodes = []
            } else if sources.count == 1 {
                selectedSource = sources[0]
                await loadEpisodes()
            } else {
                selectedSource = sources.first
                await loadEpisodes()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadEpisodes() async {
        guard let type = selectedType, let source = selectedSource else {
            episodes = []
            return
        }
        loading = true
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.episodes(releaseId: releaseId, typeId: type.id, sourceId: source.id)
            episodes = resp.episodes ?? []
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Hashable context passed to the player.
struct PlayerContext: Hashable {
    let releaseId: Int
    let releaseTitle: String
    let sourceId: Int
    let episode: Episode
    let type: EpisodeType?
    let source: EpisodeSource?
}
