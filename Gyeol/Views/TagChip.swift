import SwiftUI

/// Pushed when a tag is tapped anywhere in the app.
struct TagRoute: Hashable {
    let tag: String
}

struct TagChip: View {
    let tag: String
    var tint: Color = .accentColor
    var trailingSystemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption.weight(.medium))
            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .foregroundStyle(tint)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

/// The tags on a card. Each one is a link that rebuilds a timeline from every milestone
/// sharing it.
struct TagLinkRow: View {
    let tags: [String]
    let tint: Color

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(tags, id: \.self) { tag in
                NavigationLink(value: TagRoute(tag: tag)) {
                    TagChip(tag: tag, tint: tint)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
