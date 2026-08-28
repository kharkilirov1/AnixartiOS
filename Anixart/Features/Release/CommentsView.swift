import SwiftUI
import Kingfisher

// MARK: - Comments (with replies, votes, spoilers)

struct CommentsView: View {
    let releaseId: Int

    @State private var comments: [ReleaseComment] = []
    @State private var page = 0
    @State private var loading = false
    @State private var canLoadMore = true
    @State private var error: String?
    @State private var newComment = ""
    @State private var isSpoiler = false
    @State private var replyTo: ReleaseComment?
    @State private var sending = false
    @State private var sendingError: String?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            composer

            if comments.isEmpty && loading {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12).fill(Theme.tertiary).frame(height: 70).shimmer()
                }
            } else if comments.isEmpty, let error {
                ErrorView(message: error) { Task { await load(reset: true) } }
            } else if comments.isEmpty {
                EmptyStateView(text: "Комментариев пока нет")
            } else {
                ForEach(comments) { comment in
                    CommentCell(comment: comment, onReply: {
                        replyTo = comment
                    }, onVote: { dir in
                        Task { await vote(comment, dir) }
                    }, onDeleted: {
                        comments.removeAll { $0.id == comment.id }
                    })
                }
                if canLoadMore {
                    Button {
                        Task { await load(reset: false) }
                    } label: {
                        HStack {
                            if loading { ProgressView().tint(Theme.inkSecondary) }
                            Text("Ещё комментарии")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .task { await load(reset: true) }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let replyTo {
                HStack {
                    Text("Ответ → \(replyTo.profile?.login ?? "")")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkTertiary)
                    Spacer()
                    Button {
                        self.replyTo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
            }

            TextField("Написать комментарий…", text: $newComment, axis: .vertical)
                .lineLimit(2...5)
                .padding(10)
                .background(Theme.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.inkPrimary)

            if let sendingError {
                Text(sendingError)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.carmineLight)
            }

            HStack {
                Toggle("Спойлер", isOn: $isSpoiler)
                    .toggleStyle(.button)
                    .tint(Theme.carmine)
                    .font(.system(size: 12))
                Spacer()
                Button {
                    Task { await send() }
                } label: {
                    if sending {
                        ProgressView().tint(Theme.carmine)
                    } else {
                        Text("Отправить")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(newComment.isEmpty ? Theme.tertiary : Theme.carmine)
                            .clipShape(Capsule())
                    }
                }
                .disabled(newComment.isEmpty || sending)
            }
        }
    }

    private func send() async {
        sending = true
        sendingError = nil
        defer { sending = false }
        do {
            let resp = try await APIClient.shared.addComment(
                releaseId: releaseId,
                message: newComment,
                parentCommentId: replyTo?.id,
                isSpoiler: isSpoiler
            )
            if resp.code == 0 {
                newComment = ""
                isSpoiler = false
                replyTo = nil
                await load(reset: true)
            } else {
                sendingError = commentError(resp.code ?? -1)
            }
        } catch {
            sendingError = error.localizedDescription
        }
    }

    private func commentError(_ code: Int) -> String {
        switch code {
        case 5: return "Комментарий слишком короткий"
        case 6: return "Комментарий слишком длинный"
        case 7: return "Слишком часто — подождите немного"
        case 8: return "Вы в чёрном списке автора"
        default: return "Не удалось отправить (код \(code))"
        }
    }

    private func vote(_ comment: ReleaseComment, _ direction: Int) async {
        // direction: +1 like (vote 2), -1 dislike (vote 1)
        let voteValue = direction > 0 ? 2 : 1
        _ = try? await APIClient.shared.voteComment(commentId: comment.id, vote: voteValue)
        await load(reset: true)
    }

    private func load(reset: Bool) async {
        if reset {
            page = 0
            canLoadMore = true
            comments = []
            error = nil
        }
        guard canLoadMore, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let resp = try await APIClient.shared.releaseComments(releaseId: releaseId, page: page)
            let items = resp.content ?? []
            comments += items
            canLoadMore = items.count >= 20
            page += 1
        } catch {
            if comments.isEmpty { self.error = error.localizedDescription }
        }
    }
}

// MARK: - Comment cell

struct CommentCell: View {
    let comment: ReleaseComment
    var onReply: () -> Void
    var onVote: (Int) -> Void
    var onDeleted: () -> Void

    @State private var revealed = false
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                KFImage(URL(string: comment.profile?.avatar ?? ""))
                    .placeholder { Circle().fill(Theme.tertiary) }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        NavigationLink(value: comment.profile?.id ?? 0) {
                            Text(comment.profile?.login ?? "")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.inkPrimary)
                        }
                        .buttonStyle(.plain)
                        if let role = comment.profile?.roles?.first, let colorHex = role.color {
                            Text(role.name ?? "")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(hexString: colorHex))
                        }
                    }
                    Text(relativeTime(comment.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkTertiary)
                }

                Spacer()

                if comment.isEdited == true {
                    Text("изменён")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }

            messageBody

            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    Button { onVote(1) } label: {
                        Image(systemName: comment.vote == 2 ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Text("\(comment.voteCount ?? 0)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                    Button { onVote(-1) } label: {
                        Image(systemName: comment.vote == 1 ? "arrowtriangle.down.fill" : "arrowtriangle.down")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                .buttonStyle(.plain)

                if let replies = comment.replyCount, replies > 0 {
                    Text("Ответы: \(replies)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkTertiary)
                }

                Spacer()

                if comment.profile?.id == appState.myProfileId {
                    Button(role: .destructive) {
                        Task {
                            let resp = try? await APIClient.shared.deleteComment(commentId: comment.id)
                            if resp?.code == 0 { onDeleted() }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var messageBody: some View {
        let text = comment.message ?? ""
        if comment.isSpoiler == true && !revealed {
            Button {
                revealed = true
            } label: {
                Text("Спойлер — нажмите, чтобы показать")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Theme.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        } else {
            (Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSecondary))
                .textSelection(.enabled)
                .onTapGesture {} // keep text selectable without blocking scroll
                .onLongPressGesture { onReply() }
        }
    }

    private func relativeTime(_ timestamp: Int?) -> String {
        guard let timestamp else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension Color {
    init(hexString: String) {
        var value: UInt64 = 0
        var hex = hexString.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        Scanner(string: hex).scanHexInt64(&value)
        self.init(hex: UInt32(value & 0xFFFFFF))
    }
}
