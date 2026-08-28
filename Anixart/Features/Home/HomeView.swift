import SwiftUI

// MARK: - Home (tabs: Актуальное / Онгоинги / Завершённые / Фильмы / OVA / Анонсы)

enum HomeTab: String, CaseIterable, Identifiable {
    case actual = "Актуальное"
    case ongoing = "Онгоинги"
    case finished = "Завершённые"
    case movies = "Фильмы"
    case ova = "OVA"
    case upcoming = "Анонсы"

    var id: String { rawValue }

    var filter: FilterRequestDTO {
        var f = FilterRequestDTO()
        f.sort = 0
        switch self {
        case .actual: f.categoryId = 1
        case .ongoing: f.categoryId = 1; f.statusId = 2
        case .finished: f.categoryId = 1; f.statusId = 1
        case .movies: f.categoryId = 2
        case .ova: f.categoryId = 3
        case .upcoming: f.categoryId = 1; f.statusId = 3
        }
        return f
    }
}

enum HomeRoute: Hashable {
    case schedule
    case random
    case diagnostics
}

struct HomeView: View {
    @State private var tab: HomeTab = .actual

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HomeTab.allCases) { t in
                        Chip(text: t.rawValue, selected: t == tab) { tab = t }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Theme.bg)

            ReleaseFeedView(filter: tab.filter)
        }
        .background(Theme.bg)
        .navigationTitle("Главная")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: HomeRoute.schedule) {
                    Image(systemName: "calendar")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: HomeRoute.random) {
                    Image(systemName: "dice")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: HomeRoute.diagnostics) {
                    Image(systemName: "stethoscope")
                }
            }
        }
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .schedule: ScheduleView()
            case .random: RandomRollView()
            case .diagnostics: DiagnosticsView()
            }
        }
    }
}

// MARK: - Infinite pageable feed

struct ReleaseFeedView: View {
    let filter: FilterRequestDTO
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
                } else if let error {
                    ErrorView(message: error) { Task { await load(reset: true) } }
                } else {
                    ReleaseGrid(releases: releases)
                    if loading && !releases.isEmpty {
                        ProgressView().padding(.vertical, 12)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .task(id: filter) {
            await load(reset: true)
        }
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
            let resp = try await APIClient.shared.filter(page: page, filter)
            let items = resp.content ?? []
            if reset { releases = items } else { releases += items }
            canLoadMore = items.count >= 20
            page += 1
        } catch {
            if releases.isEmpty { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Schedule

struct ScheduleView: View {
    @State private var schedule: ScheduleResponse?
    @State private var error: String?
    @State private var selectedDay = (Calendar.current.component(.weekday, from: Date()) + 5) % 7 + 1

    private let dayNames = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    /// Monday = 1 ... Sunday = 7.
    private var todayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7 + 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { day in
                    let isToday = day == todayIndex
                    Button {
                        selectedDay = day
                    } label: {
                        Text(dayNames[day - 1])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selectedDay == day ? .white : (isToday ? Theme.carmine : Theme.inkSecondary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedDay == day ? Theme.carmine : Theme.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(16)

            if let schedule {
                ScrollView {
                    let items = items(for: selectedDay, in: schedule)
                    if items.isEmpty {
                        EmptyStateView(text: "Нет релизов в этот день")
                    } else {
                        ReleaseGrid(releases: items)
                    }
                }
            } else if let error {
                ErrorView(message: error) { Task { await load() } }
                    .frame(maxHeight: .infinity)
            } else {
                ProgressView().frame(maxHeight: .infinity)
            }
        }
        .background(Theme.bg)
        .navigationTitle("Расписание")
        .task { await load() }
    }

    private func load() async {
        error = nil
        do {
            schedule = try await APIClient.shared.schedule()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func items(for weekday: Int, in s: ScheduleResponse) -> [Release] {
        // Calendar weekday: 1=Sun...7=Sat; API: monday...sunday
        switch weekday {
        case 1: return s.sunday ?? []
        case 2: return s.monday ?? []
        case 3: return s.tuesday ?? []
        case 4: return s.wednesday ?? []
        case 5: return s.thursday ?? []
        case 6: return s.friday ?? []
        case 7: return s.saturday ?? []
        default: return []
        }
    }
}

// MARK: - Random roll (roulette)

struct RandomRollView: View {
    @State private var release: Release?
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            if let release {
                ReleaseDetailStub(release: release)
            } else if loading {
                ProgressView().frame(maxHeight: .infinity)
            } else if let error {
                ErrorView(message: error) { Task { await roll() } }
                    .frame(maxHeight: .infinity)
            } else {
                EmptyStateView(text: "Нажмите, чтобы крутить рулетку")
                    .frame(maxHeight: .infinity)
            }

            PrimaryButton(title: "Крутить", loading: loading) {
                Task { await roll() }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Theme.bg)
        .navigationTitle("Рулетка")
        .task { await roll() }
    }

    private func roll() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.randomRelease()
            if let r = resp.release {
                release = r
            } else {
                error = "Сервер не вернул релиз"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct ReleaseDetailStub: View {
    let release: Release
    var body: some View {
        VStack(spacing: 14) {
            KFImage(URL(string: release.image ?? ""))
                .placeholder { Rectangle().fill(Theme.tertiary) }
                .resizable()
                .aspectRatio(2 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 60)
            Text(release.titleRu ?? "")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.inkPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            if let grade = release.grade, grade > 0 {
                GradePill(grade: grade)
            }
            Text([release.year ?? "", release.genres ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkTertiary)
                .padding(.horizontal, 16)
        }
    }
}

import Kingfisher
