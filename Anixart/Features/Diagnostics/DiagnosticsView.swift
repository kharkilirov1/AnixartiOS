import SwiftUI

/// On-device network diagnostics: runs each critical step separately so the
/// exact failure point (DNS/TLS, HTTP status, app code, JSON decoding) is visible.
struct DiagnosticsView: View {
    @State private var lines: [String] = []
    @State private var running = false

    var body: some View {
        List {
            Section {
                Button {
                    Task { await runTests() }
                } label: {
                    HStack {
                        if running { ProgressView().tint(Theme.carmine) }
                        Text("Запустить тесты")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.carmine)
                    }
                }
                .disabled(running)
            } footer: {
                Text("Тесты идут по очереди: подпись → конфиг → расписание → фильтр → поиск. Каждый шаг покажет, на чём обрывается связь.")
            }

            Section("Результаты") {
                if lines.isEmpty {
                    Text("Пока пусто — нажмите «Запустить тесты»")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkTertiary)
                }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(line.contains("✗") ? Theme.carmineLight : Theme.inkPrimary)
                        .textSelection(.enabled)
                }
            }

            Section("Последние ошибки API") {
                let errors = APIClient.lastErrorsSnapshot()
                if errors.isEmpty {
                    Text("Ошибок не зафиксировано")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkTertiary)
                }
                ForEach(Array(errors.reversed().enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.inkSecondary)
                        .textSelection(.enabled)
                }
            }

            Section("Окружение") {
                envRow("Активный API", APIClient.activeBase)
                Button {
                    APIClient.toggleBase()
                    lines.append("— API переключён на \(APIClient.activeBase) —")
                } label: {
                    Text("Переключить на \(APIClient.activeBase == APIClient.primaryBase ? "запасной (api-s2)" : "основной (api-s)")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.carmine)
                }
                envRow("Токен", TokenStore.load() != nil ? "сохранён" : "нет (гость)")
                envRow("iOS", ProcessInfo.processInfo.operatingSystemVersionString)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Диагностика")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func envRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.inkTertiary)
            Spacer()
            Text(value).foregroundStyle(Theme.inkPrimary)
        }
        .font(.system(size: 13))
    }

    private func add(_ line: String) {
        lines.append(line)
    }

    private func runTests() async {
        running = true
        lines = []
        defer { running = false }

        // 1. Sign generation (pure local crypto — no network)
        let sign = PoliceSign.make()
        add(sign.isEmpty ? "✗ Sign: пустой" : "✓ Sign: сгенерирован (\(sign.count) симв.)")

        // 2. Toggles (GET, no token required)
        await step("Конфиг (config/toggles)") {
            let t: Toggles = try await APIClient.shared.toggles()
            return "✓ toggles: baseUrl=\(t.baseUrl ?? "-") kodik=\(t.kodikVideoLinksUrl != nil)"
        }

        // 3. Schedule (GET + token=)
        await step("Расписание (schedule)") {
            let s: ScheduleResponse = try await APIClient.shared.schedule()
            let count = (s.monday ?? []).count + (s.friday ?? []).count
            return "✓ schedule: пн=\((s.monday ?? []).count), пт=\((s.friday ?? []).count) записей"
        }

        // 4. Filter feed (POST JSON — the Home screen request)
        await step("Фильтр (filter/0)") {
            var f = FilterRequestDTO()
            f.categoryId = 1
            f.sort = 0
            let r: Pageable<Release> = try await APIClient.shared.filter(page: 0, f)
            return "✓ filter: \(r.content?.count ?? 0) релизов, первая страница"
        }

        // 5. Search (POST)
        await step("Поиск (search/releases)") {
            let r: Pageable<Release> = try await APIClient.shared.searchReleases(query: "naruto", page: 0)
            return "✓ search: \(r.content?.count ?? 0) результатов"
        }

        // 6. Random
        await step("Рулетка (release/random)") {
            let r: ReleaseWrapper = try await APIClient.shared.randomRelease()
            return "✓ random: \(r.release?.titleRu ?? "-")"
        }

        add("— Тесты завершены —")
    }

    private func step(_ name: String, _ block: () async throws -> String) async {
        do {
            let result = try await block()
            add(result)
        } catch let apiError as APIError {
            add("✗ \(name): \(apiError.message)")
        } catch let urlError as URLError {
            add("✗ \(name): сеть [\(urlError.code.rawValue)] \(urlError.localizedDescription)")
        } catch let decodingError as DecodingError {
            add("✗ \(name): декодирование \(decodingError)")
        } catch {
            add("✗ \(name): \(error.localizedDescription)")
        }
    }
}
