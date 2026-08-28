import SwiftUI
import UIKit
import Kingfisher

// MARK: - Theme (ported from anixart_next tailwind tokens)

enum Theme {
    static let bg = Color(hex: 0x0F0F12)
    static let card = Color(hex: 0x17171C)
    static let secondary = Color(hex: 0x1F1F26)
    static let tertiary = Color(hex: 0x2A2A33)
    static let carmine = Color(hex: 0xF04E4E)
    static let carmineDark = Color(hex: 0xDC2F2F)
    static let carmineLight = Color(hex: 0xF97171)
    static let inkPrimary = Color(hex: 0xF5F5F7)
    static let inkSecondary = Color(hex: 0xA1A1AA)
    static let inkTertiary = Color(hex: 0x71717A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Poster card

struct ReleaseCard: View {
    let release: Release
    var width: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                KFImage(URL(string: release.image ?? ""))
                    .placeholder { Rectangle().fill(Theme.tertiary) }
                    .resizable()
                    .aspectRatio(2 / 3, contentMode: .fill)
                    .frame(width: width, height: width * 1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if release.isOngoing {
                    Text("ОНГ")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.carmine)
                        .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .bottomRight]))
                }

                if let grade = release.grade, grade > 0 {
                    GradePill(grade: grade)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(6)
                }
            }
            .frame(width: width, height: width * 1.5)

            Text(release.titleRu ?? release.titleOriginal ?? "")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.inkPrimary)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkTertiary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts: [String] = []
        if let year = release.year, !year.isEmpty { parts.append(year) }
        if let cat = release.category?.name { parts.append(cat) }
        if let released = release.episodesReleased {
            parts.append(release.isOngoing ? "\(released) эп." : "\(released) эп.")
        }
        return parts.joined(separator: " · ")
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

struct GradePill: View {
    let grade: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9))
            Text(String(format: "%.2f", grade))
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(Theme.carmine)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Theme.carmine.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Horizontal releases row

struct ReleaseRow: View {
    let title: String
    let releases: [Release]
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.inkPrimary)
                Spacer()
                if onSeeAll != nil {
                    Button("Смотреть все") { onSeeAll?() }
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.carmine)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(releases) { release in
                        NavigationLink(value: release) {
                            ReleaseCard(release: release)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Grid

struct ReleaseGrid: View {
    let releases: [Release]
    var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(releases) { release in
                NavigationLink(value: release) {
                    ReleaseCard(release: release)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Common UI

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Theme.inkPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }
}

struct ErrorView: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(Theme.inkTertiary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Повторить") { retry() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.carmine)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct SkeletonCard: View {
    var width: CGFloat = 150
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Theme.tertiary)
            .frame(width: width, height: width * 1.5)
            .shimmer()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.06), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: phase * geo.size.width * 1.6)
                }
                .clipped()
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct Chip: View {
    let text: String
    var selected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
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

struct EmptyStateView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Theme.inkTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
    }
}
