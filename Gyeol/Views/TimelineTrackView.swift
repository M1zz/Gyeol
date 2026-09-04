import SwiftUI
import SwiftData

/// The timeline itself: a vertical spine running down the screen where the distance
/// between two nodes is proportional to the time that actually elapsed between them.
/// One points-per-day scale is applied across the whole track, so a three-year jump
/// really is drawn far longer than a three-day one. Tapping a node slides its photo
/// and note open in place.
struct TimelineTrackView: View {
    let events: [TimelineEvent]
    let color: Color
    @Binding var expanded: PersistentIdentifier?
    var onEdit: (TimelineEvent) -> Void

    var body: some View {
        let scale = TrackScale(dates: events.map(\.date))

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                        if index > 0 {
                            TimeGapView(from: events[index - 1].date, to: event.date, scale: scale)
                        }
                        TimelineNodeView(
                            event: event,
                            color: color,
                            position: position(of: index),
                            showsYear: index == 0 || events[index - 1].date.yearLabel != event.date.yearLabel,
                            isExpanded: expanded == event.id,
                            onTap: { toggle(event, proxy: proxy) },
                            onEdit: { onEdit(event) }
                        )
                        .id(event.id)
                        .zIndex(expanded == event.id ? 1 : 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func position(of index: Int) -> NodePosition {
        if events.count == 1 { return .only }
        if index == 0 { return .first }
        if index == events.count - 1 { return .last }
        return .middle
    }

    private func toggle(_ event: TimelineEvent, proxy: ScrollViewProxy) {
        withAnimation(.snappy(duration: 0.32)) {
            expanded = (expanded == event.id) ? nil : event.id
            if expanded != nil {
                proxy.scrollTo(event.id, anchor: UnitPoint(x: 0, y: 0.08))
            }
        }
    }
}

// MARK: - Scale

enum TrackMetrics {
    static let spineX: CGFloat = 28
    /// Distance from a node's top edge to the centre of its dot.
    static let dotCentreY: CGFloat = 23
    static let minGap: CGFloat = 26
    static let maxGap: CGFloat = 560
    /// Roughly how tall the whole track should be before clamping kicks in.
    static let idealTotal: CGFloat = 2400
}

/// Maps elapsed time to vertical distance with a single scale for the whole track.
struct TrackScale {
    let pointsPerDay: CGFloat

    init(dates: [Date]) {
        guard let first = dates.first, let last = dates.last, dates.count > 1 else {
            pointsPerDay = 1
            return
        }
        let span = max(1, last.timeIntervalSince(first) / 86_400)
        pointsPerDay = min(max(TrackMetrics.idealTotal / CGFloat(span), 0.25), 40)
    }

    /// The drawn height for a gap, plus whether it had to be cut short to stay scrollable.
    func gap(days: Double) -> (height: CGFloat, isCompressed: Bool) {
        let raw = CGFloat(max(0, days)) * pointsPerDay
        return (min(max(raw, TrackMetrics.minGap), TrackMetrics.maxGap), raw > TrackMetrics.maxGap)
    }
}

// MARK: - Gap

private struct TimeGapView: View {
    let from: Date
    let to: Date
    let scale: TrackScale

    var body: some View {
        let days = to.timeIntervalSince(from) / 86_400
        let metrics = scale.gap(days: days)

        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: metrics.height)
            .overlay(alignment: .topLeading) {
                VerticalLine()
                    .stroke(
                        Color(.separator),
                        style: metrics.isCompressed
                            ? StrokeStyle(lineWidth: 2, dash: [3, 6])
                            : StrokeStyle(lineWidth: 2)
                    )
                    .frame(width: 2, height: metrics.height)
                    .offset(x: TrackMetrics.spineX - 1)
            }
            .overlay(alignment: .leading) {
                if metrics.height >= 18 {
                    Text(DurationLabel.between(from, to))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, TrackMetrics.spineX + 14)
                }
            }
    }
}

private struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Node

enum NodePosition { case first, middle, last, only }

private struct TimelineNodeView: View {
    let event: TimelineEvent
    let color: Color
    let position: NodePosition
    let showsYear: Bool
    let isExpanded: Bool
    var onTap: () -> Void
    var onEdit: () -> Void

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            dot
            card
        }
        .background(alignment: .topLeading) { spine }
        .animation(.snappy(duration: 0.32), value: isExpanded)
    }

    private var dot: some View {
        Circle()
            .fill(isExpanded ? color : Color(.systemGroupedBackground))
            .overlay(Circle().strokeBorder(isExpanded ? color : Color(.tertiaryLabel), lineWidth: 2))
            .frame(width: 14, height: 14)
            .scaleEffect(isExpanded ? 1.3 : 1)
            .frame(width: TrackMetrics.spineX * 2, height: TrackMetrics.dotCentreY * 2, alignment: .center)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if isExpanded { detail }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(shape)
        .overlay(shape.strokeBorder(isExpanded ? color.opacity(0.45) : .clear, lineWidth: 1.5))
        .shadow(color: .black.opacity(isExpanded ? 0.10 : 0.04),
                radius: isExpanded ? 14 : 5,
                y: isExpanded ? 7 : 2)
        .contentShape(shape)
        .onTapGesture(perform: onTap)
        .padding(.bottom, 2)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            if showsYear {
                Text(event.date.yearLabel)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(color)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(event.date.nodeDateLabel)
                    .font(.system(size: 14, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if !isExpanded, event.photoData != nil {
                    Image(systemName: "photo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Text(event.title.isEmpty ? "제목 없음" : event.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(event.title.isEmpty ? .tertiary : .primary)
                .fixedSize(horizontal: false, vertical: true)
            if !isExpanded, !event.note.isEmpty {
                Text(event.note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let data = event.photoData, let image = UIImage(data: data) {
                Color.clear
                    .frame(height: 220)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            if !event.note.isEmpty {
                Text(event.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(action: onEdit) {
                Label("수정", systemImage: "pencil")
            }
            .font(.footnote.weight(.medium))
            .buttonStyle(.bordered)
            .tint(color)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
    }

    @ViewBuilder
    private var spine: some View {
        let line = Color(.separator)
        switch position {
        case .only:
            EmptyView()
        case .first:
            Rectangle().fill(line)
                .frame(width: 2)
                .padding(.top, TrackMetrics.dotCentreY)
                .offset(x: TrackMetrics.spineX - 1)
        case .middle:
            Rectangle().fill(line)
                .frame(width: 2)
                .offset(x: TrackMetrics.spineX - 1)
        case .last:
            Rectangle().fill(line)
                .frame(width: 2, height: TrackMetrics.dotCentreY)
                .offset(x: TrackMetrics.spineX - 1)
        }
    }
}
