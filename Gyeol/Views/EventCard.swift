import SwiftUI

/// What a card draws, as plain values — so the editor can preview a draft that hasn't
/// been saved yet, and the card views stay independent of SwiftData.
struct CardContent {
    var date: Date
    var title: String
    var note: String
    var tags: [String] = []
    var photoData: Data?
    var showsYear: Bool = false

    var displayTitle: String { title.isEmpty ? "제목 없음" : title }
    var hasTitle: Bool { !title.isEmpty }
    var image: UIImage? { photoData.flatMap(UIImage.init(data:)) }
}

struct EventCard: View {
    let content: CardContent
    let style: CardStyle
    let color: Color
    let isExpanded: Bool
    /// Off for the editor preview, where there is no navigation stack to push onto.
    var tagsAreLinks: Bool = true
    var onEdit: (() -> Void)?

    var body: some View {
        switch style {
        case .classic:
            ClassicCard(content: content, color: color, isExpanded: isExpanded,
                        tagsAreLinks: tagsAreLinks, onEdit: onEdit)
        case .poster:
            PosterCard(content: content, color: color, isExpanded: isExpanded,
                       tagsAreLinks: tagsAreLinks, onEdit: onEdit)
        case .film:
            FilmCard(content: content, color: color, isExpanded: isExpanded,
                     tagsAreLinks: tagsAreLinks, onEdit: onEdit)
        case .editorial:
            EditorialCard(content: content, color: color, isExpanded: isExpanded,
                          tagsAreLinks: tagsAreLinks, onEdit: onEdit)
        }
    }
}

// MARK: - Shared surface

private struct CardSurface: ViewModifier {
    let isExpanded: Bool
    let color: Color
    var filled: Bool = true

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        content
            .background(filled ? Color(.secondarySystemGroupedBackground) : Color.clear)
            .clipShape(shape)
            .overlay(shape.strokeBorder(isExpanded ? color.opacity(0.45) : .clear, lineWidth: 1.5))
            .shadow(color: .black.opacity(isExpanded ? 0.10 : 0.04),
                    radius: isExpanded ? 14 : 5,
                    y: isExpanded ? 7 : 2)
    }
}

private extension View {
    func cardSurface(isExpanded: Bool, color: Color, filled: Bool = true) -> some View {
        modifier(CardSurface(isExpanded: isExpanded, color: color, filled: filled))
    }
}

private struct CardEditButton: View {
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("수정", systemImage: "pencil")
        }
        .font(.footnote.weight(.medium))
        .buttonStyle(.bordered)
        .tint(tint)
    }
}

/// Photo that fills a fixed box without letting its intrinsic size widen the card.
private struct PhotoBox: View {
    let image: UIImage
    var width: CGFloat?
    let height: CGFloat
    var cornerRadius: CGFloat = 12

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - 기본

private struct ClassicCard: View {
    let content: CardContent
    let color: Color
    let isExpanded: Bool
    let tagsAreLinks: Bool
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                if content.showsYear {
                    Text(content.date.yearLabel)
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(color)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(content.date.nodeDateLabel)
                        .font(.system(size: 14, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if !isExpanded, content.photoData != nil {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Text(content.displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(content.hasTitle ? .primary : .tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                if !isExpanded, !content.note.isEmpty {
                    Text(content.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !content.tags.isEmpty {
                    TagLinkRow(tags: content.tags, tint: color, isInteractive: tagsAreLinks)
                        .padding(.top, 2)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if let image = content.image {
                        PhotoBox(image: image, height: 220)
                    }
                    if !content.note.isEmpty {
                        Text(content.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let onEdit { CardEditButton(tint: color, action: onEdit) }
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(isExpanded: isExpanded, color: color)
    }
}

// MARK: - 포스터

private struct PosterCard: View {
    let content: CardContent
    let color: Color
    let isExpanded: Bool
    let tagsAreLinks: Bool
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(dateLine)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.85))
            Text(content.displayTitle)
                .font(.system(size: isExpanded ? 30 : 22, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if isExpanded, !content.note.isEmpty {
                Text(content.note)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
                    .transition(.opacity)
            }
            if !content.tags.isEmpty {
                TagLinkRow(tags: content.tags, tint: .white,
                           chipStyle: .material, isInteractive: tagsAreLinks)
            }
            if isExpanded, let onEdit {
                CardEditButton(tint: .white, action: onEdit)
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(16)
        // Reserved space above the text is what the photo shows through.
        .padding(.top, isExpanded ? 190 : 78)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { backdrop }
        .cardSurface(isExpanded: isExpanded, color: color, filled: false)
    }

    private var backdrop: some View {
        ZStack {
            if let image = content.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [color, color.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            LinearGradient(
                colors: [.black.opacity(0.10), .black.opacity(0.35), .black.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var dateLine: String {
        content.showsYear || isExpanded
            ? "\(content.date.yearLabel) · \(content.date.nodeDateLabel)"
            : content.date.nodeDateLabel
    }
}

// MARK: - 필름

private struct FilmCard: View {
    let content: CardContent
    let color: Color
    let isExpanded: Bool
    let tagsAreLinks: Bool
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = content.image {
                PhotoBox(image: image, height: isExpanded ? 230 : 128, cornerRadius: 3)
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(height: isExpanded ? 150 : 84)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        Image(systemName: "camera")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(content.date.stampLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(color)
                Text(content.displayTitle)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(content.hasTitle ? .primary : .tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                if !content.note.isEmpty {
                    Text(content.note)
                        .font(.system(size: 12.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .lineLimit(isExpanded ? nil : 1)
                }
                if !content.tags.isEmpty {
                    TagLinkRow(tags: content.tags, tint: color, isInteractive: tagsAreLinks)
                        .padding(.top, 1)
                }
                if isExpanded, let onEdit {
                    CardEditButton(tint: color, action: onEdit)
                        .transition(.opacity)
                }
            }
        }
        .padding(12)
        // A print's matte is deeper along the bottom edge.
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(isExpanded: isExpanded, color: color)
    }
}

// MARK: - 여백

private struct EditorialCard: View {
    let content: CardContent
    let color: Color
    let isExpanded: Bool
    let tagsAreLinks: Bool
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(content.date.dayNumber)
                        .font(.system(size: isExpanded ? 52 : 38, weight: .regular, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(content.date.monthLabel)
                            .font(.system(size: 13, design: .serif))
                        Text(content.date.yearLabel)
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(.secondary)
                    }
                }

                Rectangle()
                    .fill(color.opacity(0.25))
                    .frame(height: 1)

                Text(content.displayTitle)
                    .font(.system(size: isExpanded ? 22 : 17, weight: .semibold, design: .serif))
                    .foregroundStyle(content.hasTitle ? .primary : .tertiary)
                    .fixedSize(horizontal: false, vertical: true)

                if !content.note.isEmpty {
                    Text(content.note)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineSpacing(6)
                        .lineLimit(isExpanded ? nil : 1)
                }
                if !content.tags.isEmpty {
                    TagLinkRow(tags: content.tags, tint: color, isInteractive: tagsAreLinks)
                }
                if isExpanded, let onEdit {
                    CardEditButton(tint: color, action: onEdit)
                        .transition(.opacity)
                }
            }

            if let image = content.image {
                PhotoBox(
                    image: image,
                    width: isExpanded ? 92 : 58,
                    height: isExpanded ? 116 : 58,
                    cornerRadius: 8
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(isExpanded: isExpanded, color: color)
    }
}

// MARK: - Picker

/// A miniature schematic of each style, so the choice reads at a glance in the editor.
struct CardStyleSwatch: View {
    let style: CardStyle
    let color: Color
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            schematic
                .frame(width: 68, height: 84)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? color : Color(.separator),
                                      lineWidth: isSelected ? 2 : 1)
                }
            Text(style.label)
                .font(.caption2.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? color : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style.label) 디자인")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var schematic: some View {
        switch style {
        case .classic:
            VStack(alignment: .leading, spacing: 4) {
                bar(20, 3, 0.35)
                bar(42, 6, 0.8)
                bar(34, 3, 0.3)
                block(height: 26)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .poster:
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [color.opacity(0.85), color.opacity(0.3)],
                               startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 3) {
                    bar(16, 3, 0.9, tint: .white)
                    bar(44, 7, 1, tint: .white)
                }
                .padding(8)
            }

        case .film:
            VStack(alignment: .leading, spacing: 6) {
                block(height: 34)
                bar(16, 3, 0.4)
                bar(40, 5, 0.75)
            }
            .padding(7)
            .padding(.bottom, 7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .editorial:
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("5")
                        .font(.system(size: 24, design: .serif))
                        .foregroundStyle(color)
                    Rectangle().fill(color.opacity(0.3)).frame(width: 34, height: 1)
                    bar(32, 5, 0.75)
                    bar(24, 3, 0.3)
                }
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.tertiaryLabel).opacity(0.45))
                    .frame(width: 13, height: 17)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func bar(_ width: CGFloat, _ height: CGFloat, _ opacity: Double,
                     tint: Color = .primary) -> some View {
        Capsule().fill(tint.opacity(opacity)).frame(width: width, height: height)
    }

    private func block(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.tertiaryLabel).opacity(0.45))
            .frame(height: height)
            .frame(maxWidth: .infinity)
    }
}
