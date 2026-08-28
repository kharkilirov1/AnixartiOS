import SwiftUI

// MARK: - Auth screen (signIn / signUp + verify / restore)

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var mode: Mode = .signIn
    @State private var showDiagnostics = false

    enum Mode: Hashable {
        case signIn, signUp, verify(SignUpContext), restore, restoreVerify(RestoreContext)
    }

    struct SignUpContext: Hashable {
        var login: String
        var email: String
        var password: String
        var hash: String
    }

    struct RestoreContext: Hashable {
        var data: String
        var password: String = ""
        var hash: String = ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(spacing: 10) {
                LogoView()
                Text("Anixart")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Theme.inkPrimary)
                Text("Аниме без границ")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkTertiary)
            }

            Spacer(minLength: 24)

            switch mode {
            case .signIn:
                SignInForm(mode: $mode)
            case .signUp:
                SignUpForm(mode: $mode)
            case .verify(let ctx):
                VerifyForm(mode: $mode, context: ctx)
            case .restore:
                RestoreForm(mode: $mode)
            case .restoreVerify(let ctx):
                RestoreVerifyForm(mode: $mode, context: ctx)
            }

            Spacer()

            Button {
                showDiagnostics = true
            } label: {
                Label("Диагностика сети", systemImage: "stethoscope")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.15), value: mode)
        .sheet(isPresented: $showDiagnostics) {
            NavigationStack { DiagnosticsView() }
                .presentationDetents([.large])
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Logo

struct LogoView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.carmine)
                .frame(width: 64, height: 64)
            Path { p in
                p.move(to: CGPoint(x: 14, y: 40))
                p.addCurve(to: CGPoint(x: 32, y: 22), control1: CGPoint(x: 14, y: 28), control2: CGPoint(x: 22, y: 22))
                p.addCurve(to: CGPoint(x: 50, y: 40), control1: CGPoint(x: 42, y: 22), control2: CGPoint(x: 50, y: 28))
            }
            .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 64, height: 64)
        }
    }
}

// MARK: - Shared field

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var secure = false

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(placeholder.localizedCaseInsensitiveContains("email") ? .emailAddress : .default)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(14)
        .background(Theme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Theme.inkPrimary)
    }
}

struct PrimaryButton: View {
    let title: String
    var loading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(loading ? Theme.carmineDark : Theme.carmine)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(loading)
    }
}

// MARK: - Sign in

private struct SignInForm: View {
    @Environment(AppState.self) private var appState
    @Binding var mode: AuthView.Mode
    @State private var login = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            AuthTextField(placeholder: "Логин или email", text: $login)
            AuthTextField(placeholder: "Пароль", text: $password, secure: true)

            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.carmineLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Войти", loading: loading) {
                Task { await signIn() }
            }

            HStack(spacing: 16) {
                Button("Регистрация") { mode = .signUp }
                Button("Забыли пароль?") { mode = .restore }
            }
            .font(.system(size: 14))
            .foregroundStyle(Theme.inkSecondary)

            Button {
                appState.continueAsGuest()
            } label: {
                Text("Продолжить как гость")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(.top, 8)
        }
    }

    private func signIn() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.signIn(login: login, password: password)
            switch resp.code {
            case 0:
                if let token = resp.profileToken?.token, let profile = resp.profile {
                    appState.didSignIn(token: token, profile: profile)
                } else {
                    error = "Пустой ответ сервера"
                }
            case 2: error = "Неверный логин"
            case 3: error = "Неверный пароль"
            default: error = "Ошибка входа (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Sign up

private struct SignUpForm: View {
    @Binding var mode: AuthView.Mode
    @State private var login = ""
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            AuthTextField(placeholder: "Логин", text: $login)
            AuthTextField(placeholder: "Email", text: $email)
            AuthTextField(placeholder: "Пароль", text: $password, secure: true)

            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.carmineLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Зарегистрироваться", loading: loading) {
                Task { await signUp() }
            }

            Button("Уже есть аккаунт? Войти") { mode = .signIn }
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private func signUp() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.signUp(login: login, email: email, password: password)
            switch resp.code {
            case 0:
                if let hash = resp.hash {
                    mode = .verify(AuthView.SignUpContext(login: login, email: email, password: password, hash: hash))
                }
            case 5: error = "Логин уже занят"
            case 6: error = "Email уже занят"
            case 7: error = "Код уже отправлен"
            case 3: error = "Некорректный email"
            case 2: error = "Некорректный логин"
            default: error = "Ошибка регистрации (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Email verify

private struct VerifyForm: View {
    @Environment(AppState.self) private var appState
    @Binding var mode: AuthView.Mode
    let context: AuthView.SignUpContext
    @State private var code = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            Text("Код подтверждения отправлен на \(context.email)")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuthTextField(placeholder: "Код из письма", text: $code)

            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.carmineLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Подтвердить", loading: loading) {
                Task { await verify() }
            }

            Button("Отправить код ещё раз") {
                Task {
                    _ = try? await APIClient.shared.resend(
                        login: context.login, email: context.email, password: context.password, hash: context.hash
                    )
                }
            }
            .font(.system(size: 14))
            .foregroundStyle(Theme.inkSecondary)

            Button("Назад") { mode = .signUp }
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkTertiary)
        }
    }

    private func verify() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.verify(
                login: context.login, email: context.email, password: context.password,
                hash: context.hash, code: code
            )
            if resp.code == 0, let token = resp.profileToken?.token, let profile = resp.profile {
                appState.didSignIn(token: token, profile: profile)
            } else {
                error = "Неверный код (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Restore

private struct RestoreForm: View {
    @Binding var mode: AuthView.Mode
    @State private var data = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            AuthTextField(placeholder: "Логин или email", text: $data)

            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.carmineLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Восстановить пароль", loading: loading) {
                Task { await restore() }
            }

            Button("Назад ко входу") { mode = .signIn }
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private func restore() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.restore(data: data)
            if resp.code == 0, let hash = resp.hash {
                mode = .restoreVerify(AuthView.RestoreContext(data: data, hash: hash))
            } else {
                error = "Аккаунт не найден (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct RestoreVerifyForm: View {
    @Environment(AppState.self) private var appState
    @Binding var mode: AuthView.Mode
    let context: AuthView.RestoreContext
    @State private var code = ""
    @State private var newPassword = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 12) {
            AuthTextField(placeholder: "Код из письма", text: $code)
            AuthTextField(placeholder: "Новый пароль", text: $newPassword, secure: true)

            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.carmineLight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: "Сменить пароль", loading: loading) {
                Task { await restoreVerify() }
            }

            Button("Назад") { mode = .restore }
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkTertiary)
        }
    }

    private func restoreVerify() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.restoreVerify(
                data: context.data, password: newPassword, hash: context.hash, code: code
            )
            if resp.code == 0, let token = resp.profileToken?.token, let profile = resp.profile {
                appState.didSignIn(token: token, profile: profile)
            } else {
                error = "Неверный код (код \(resp.code ?? -1))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
