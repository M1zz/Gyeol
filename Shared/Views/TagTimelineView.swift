import SwiftUI
import SwiftData

/// A timeline rebuilt on the fly from one tag: every milestone carrying it, from every
/// timeline, in date order. Saving it keeps the view, not a copy of the events.
struct TagTimelineView: View {
    let tag: String

    @Environment(\.modelContext) private var context
    @Query private var allEvents: [TimelineEvent]
    @Query private var timelines: [Timeline]

    @State private var expanded: PersistentIdentifier?
    @State private var editingEvent: TimelineEvent?
    @State private var showingSave = false

    private var events: [TimelineEvent] {
        allEvents.filter { $0.hasTag(tag) }.chronological
    }

    /// A tag can only be saved once; after that the toolbar links to the saved timeline.
    private var saved: Timeline? {
        timelines.first { timeline in
            timeline.tagFilter.map { Tag.matches($0, tag) } ?? false
        }
    }

    private var tint: Color {
        saved?.color ?? Color(hex: TimelinePalette.forTag(tag))
    }

    var body: some View {
        Group {
            if events.isEmpty {
                ContentUnavailableView {
                    Label("#\(tag) 사건이 없어요", systemImage: "number")
                } description: {
                    Text("이 태그를 단 사건이 아직 없습니다.")
                }
            } else {
                TimelineTrackView(events: events, color: tint, expanded: $expanded) { event in
                    editingEvent = event
                }
            }
        }
        .background(Palette.groupedBackground)
        .navigationTitle("#\(tag)")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let saved {
                    Label("저장됨", systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(saved.color)
                } else {
                    Button {
                        showingSave = true
                    } label: {
                        Label("타임라인으로 저장", systemImage: "square.and.arrow.down")
                    }
                    .disabled(events.isEmpty)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if saved == nil, !events.isEmpty {
                Text("사건 \(events.count)개 · 저장하면 목록에 남고, 태그가 붙는 대로 계속 채워져요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
        .sheet(item: $editingEvent) { event in
            EventEditorView(timeline: event.timeline, event: event) { _ in }
        }
        .sheet(isPresented: $showingSave) {
            TimelineEditorView(timeline: nil, tagFilter: tag, suggestedName: "#\(tag)")
        }
    }
}
