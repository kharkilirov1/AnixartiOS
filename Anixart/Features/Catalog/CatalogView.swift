import SwiftUI

// MARK: - Catalog with full filter

enum CatalogSort: Int, CaseIterable, Identifiable {
    case dateUpdate = 0
    case grade = 1
    case year = 2
    case popular = 3

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .dateUpdate: return "По дате обновления"
        case .grade: return "По оценке"
        case .year: return "По году"
        case .popular: return "По популярности"
        }
    }
}

enum CatalogCategory: Int, CaseIterable, Identifiable {
    case serial = 1
    case movie = 2
    case ova = 3
    case special = 6

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .serial: return "Сериал"
        case .movie: return "Фильм"
        case .ova: return "OVA"
        case .special: return "Спешл"
        }
    }
}

enum CatalogStatus: Int, CaseIterable, Identifiable {
    case unknown = 0
    case finished = 1
    case ongoing = 2
    case upcoming = 3

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .unknown: return "Неизвестно"
        case .finished: return "Вышел"
        case .ongoing: return "Выходит"
        case .upcoming: return "Анонс"
        }
    }
}

/// Static genre list extracted from Anixart APK resources (res/values/arrays.xml).
enum Genres {
    static let all: [String] = [
        "авангард", "гурман", "драма", "комедия", "повседневность", "приключения", "романтика",
        "сверхъестественное", "спорт", "тайна", "триллер", "ужасы", "фантастика", "фэнтези",
        "экшен", "эротика", "этти",
        "детское", "дзёсей", "сэйнэн", "сёдзё", "сёдзё-ай", "сёнен", "сёнен-ай",
        "CGDCT", "антропоморфизм", "боевые искусства", "вампиры", "взрослые персонажи", "видеоигры",
        "военное", "выживание", "гарем", "гонки", "городское фэнтези", "гэг-юмор", "детектив",
        "жестокость", "забота о детях", "злодейка", "игра с высокими ставками", "идолы (жен.)",
        "идолы (муж.)", "изобразительное искусство", "исполнительское искусство", "исторический",
        "исэкай", "иясикэй", "командный спорт", "космос", "кроссдрессинг", "культура отаку",
        "любовный многоугольник", "магическая смена пола", "махо-сёдзё", "медицина", "меха",
        "мифология", "музыка", "образовательное", "организованная преступность", "пародия",
        "питомцы", "психологическое", "путешествие во времени", "работа", "реверс-гарем",
        "реинкарнация", "романтический подтекст", "самураи", "спортивные единоборства",
        "стратегические игры", "супер сила", "удостоено наград", "хулиганы", "школа", "шоу-бизнес",
    ]
}

struct CatalogView: View {
    @State private var filter = FilterRequestDTO()
    @State private var showFilter = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CatalogSort.allCases) { s in
                        Chip(text: s.title.replacingOccurrences(of: "По ", with: ""),
                             selected: filter.sort == s.rawValue) {
                            filter.sort = s.rawValue
                        }
                    }
                    Chip(text: "Фильтры", selected: activeFilterCount > 0) {
                        showFilter = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            if activeFilterCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(activeFilterLabels, id: \.self) { label in
                            Text(label)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.inkSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.tertiary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            ReleaseFeedView(filter: filter)
        }
        .background(Theme.bg)
        .navigationTitle("Каталог")
        .sheet(isPresented: $showFilter) {
            FilterSheet(filter: $filter)
                .presentationDetents([.medium, .large])
        }
    }

    private var activeFilterCount: Int {
        var count = 0
        if let cat = filter.categoryId, cat != 0 { count += 1 }
        if let st = filter.statusId { count += 1 }
        if let y = filter.startYear, y > 0 { count += 1 }
        if let g = filter.genres, !g.isEmpty { count += 1 }
        return count
    }

    private var activeFilterLabels: [String] {
        var labels: [String] = []
        if let cat = filter.categoryId, let c = CatalogCategory(rawValue: cat) { labels.append(c.title) }
        if let st = filter.statusId, let s = CatalogStatus(rawValue: st) { labels.append(s.title) }
        if let y = filter.startYear, y > 0 { labels.append("от \(y)") }
        if let g = filter.genres { labels.append(contentsOf: g) }
        return labels
    }
}

// MARK: - Filter sheet

struct FilterSheet: View {
    @Binding var filter: FilterRequestDTO
    @Environment(\.dismiss) private var dismiss
    @State private var yearFrom = 1990.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    filterSection("Тип") {
                        chips(CatalogCategory.allCases.map { ($0.title, $0.rawValue) },
                              selection: filter.categoryId) { filter.categoryId = $0 }
                    }

                    filterSection("Статус") {
                        chips([(-1, "Любой")] + CatalogStatus.allCases.map { ($0.title, $0.rawValue) },
                              selection: filter.statusId) { filter.statusId = $0 }
                    }

                    filterSection("Год от \(Int(yearFrom))") {
                        Slider(value: $yearFrom, in: 1960...2027, step: 1)
                            .tint(Theme.carmine)
                            .onChange(of: yearFrom) { _, newValue in
                                filter.startYear = Int(newValue)
                            }
                    }

                    filterSection("Жанры") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], spacing: 6) {
                            ForEach(Genres.all, id: \.self) { genre in
                                let selected = filter.genres?.contains(genre) ?? false
                                Button {
                                    if selected {
                                        filter.genres?.removeAll { $0 == genre }
                                    } else {
                                        if filter.genres == nil { filter.genres = [] }
                                        filter.genres?.append(genre)
                                    }
                                } label: {
                                    Text(genre)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                        .foregroundStyle(selected ? .white : Theme.inkSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(selected ? Theme.carmine : Theme.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    filterSection("Исключать выбранные жанры") {
                        Toggle("", isOn: Binding(
                            get: { filter.isGenresExcludeModeEnabled ?? false },
                            set: { filter.isGenresExcludeModeEnabled = $0 }
                        ))
                        .labelsHidden()
                        .tint(Theme.carmine)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Сбросить") {
                        filter = FilterRequestDTO()
                        filter.sort = 0
                        yearFrom = 1990
                    }
                    .foregroundStyle(Theme.inkSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(Theme.carmine)
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.inkPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chips(_ items: [(String, Int)], selection: Int?, handler: @escaping (Int?) -> Void) -> some View {
        FlowLayout {
            ForEach(items, id: \.1) { item in
                let selected = selection == item.1
                Button {
                    handler(selected ? nil : item.1)
                } label: {
                    Text(item.0)
                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? .white : Theme.inkSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selected ? Theme.carmine : Theme.secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { continue }
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x,
                            y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x - spacing)
        }
        return (positions, CGSize(width: min(totalWidth, maxWidth), height: y + rowHeight))
    }
}

// MARK: - Search

struct SearchView: View {
    @State private var query = ""
    @State private var scope = 0
    @State private var releases: [Release] = []
    @State private var collections: [Collection] = []
    @State private var profiles: [Profile] = []
    @State private var loading = false
    @State private var searched = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.inkTertiary)
                TextField("Поиск аниме, коллекций, профилей", text: $query)
                    .foregroundStyle(Theme.inkPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                if !query.isEmpty {
                    Button {
                        query = ""
                        releases = []; collections = []; profiles = []
                        searched = false
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkTertiary)
                    }
                }
            }
            .padding(12)
            .background(Theme.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Picker("", selection: $scope) {
                Text("Аниме").tag(0)
                Text("Коллекции").tag(1)
                Text("Профили").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                if loading && !searched {
                    ProgressView().padding(.top, 40)
                } else if !searched {
                    EmptyStateView(text: "Введите название в поиск выше")
                } else {
                    switch scope {
                    case 0:
                        if releases.isEmpty { EmptyStateView(text: "Ничего не найдено") }
                        else { ReleaseGrid(releases: releases) }
                    case 1:
                        if collections.isEmpty { EmptyStateView(text: "Ничего не найдено") }
                        else {
                            LazyVStack(spacing: 10) {
                                ForEach(collections) { collection in
                                    NavigationLink(value: collection) {
                                        CollectionRow(collection: collection)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    default:
                        if profiles.isEmpty { EmptyStateView(text: "Ничего не найдено") }
                        else {
                            LazyVStack(spacing: 10) {
                                ForEach(profiles) { profile in
                                    NavigationLink(value: profile.id) {
                                        ProfileRow(profile: profile)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .background(Theme.bg)
        .navigationTitle("Поиск")
        .onChange(of: scope) { _, _ in Task { await search() } }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        loading = true
        defer { loading = false }
        do {
            switch scope {
            case 0:
                let r = try await APIClient.shared.searchReleases(query: trimmed, page: 0)
                releases = r.content ?? []
            case 1:
                let r = try await APIClient.shared.searchCollections(query: trimmed, page: 0)
                collections = r.content ?? []
            default:
                let r = try await APIClient.shared.searchProfiles(query: trimmed, page: 0)
                profiles = r.content ?? []
            }
            searched = true
        } catch {
            searched = true
        }
    }
}
