import SwiftUI

/// Pushed when a tag is tapped anywhere in the app.
struct TagRoute: Hashable {
    let tag: String
}

/// Tinted reads well on a plain card; material is for chips sitting on a photo.
enum TagChipStyle {
    case tinted
    case material
}

struct TagChip: View {
    let tag: String
    var tint: Color = .accentColor
    var chipStyle: TagChipStyle = .tinted
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
        .background {
            switch chipStyle {
            case .tinted: Capsule().fill(tint.opacity(0.14))
            case .material: Capsule().fill(.ultraThinMaterial)
            }
        }
    }
}

/// The tags on a card. Each one is a link that rebuilds a timeline from every milestone
/// sharing it.
struct TagLinkRow: View {
    let tags: [String]
    let tint: Color
    var chipStyle: TagChipStyle = .tinted
    /// Off inside the editor preview, which has no destination to push onto.
    var isInteractive: Bool = true

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(tags, id: \.self) { tag in
                if isInteractive {
                    NavigationLink(value: TagRoute(tag: tag)) {
                        TagChip(tag: tag, tint: tint, chipStyle: chipStyle)
                    }
                    .buttonStyle(.plain)
                } else {
                    TagChip(tag: tag, tint: tint, chipStyle: chipStyle)
                }
            }
        }
    }
}
