import SwiftUI
import SwiftData

struct TimelineDetailView: View {
    @Bindable var timeline: Timeline

    @Query private var allEvents: [TimelineEvent]
    @State private var expanded: PersistentIdentifier?
    @State private var editingEvent: TimelineEvent?
    @State private var showingNewEvent = false
    @State private var showingSettings = false

    /// A saved tag timeline owns no events — it gathers them from the whole store instead.
    private var events: [TimelineEvent] {
        guard let tag = timeline.tagFilter else { return timeline.sortedEvents }
        return allEvents.filter { $0.hasTag(tag) }.chronological
    }

    var body: some View {
        Group {
            if events.isEmpty {
                emptyState
            } else {
                TimelineTrackView(events: events, color: timeline.color, expanded: $expanded) { event in
                    editingEvent = event
                }
            }
        }
        .background(Palette.groupedBackground)
        .navigationTitle(timeline.name)
        .inlineNavigationTitle()
        .toolbar {
            #if os(macOS)
            ToolbarItem {
                if !timeline.isTagTimeline {
                    Button { showingNewEvent = true } label: {
                        Label("사건 추가", systemImage: "plus")
                    }
                }
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if !timeline.isTagTimeline {
                        Button { showingNewEvent = true } label: { Label("사건 추가", systemImage: "plus") }
                    }
                    Button { showingSettings = true } label: { Label("이름·색 바꾸기", systemImage: "paintpalette") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let tag = timeline.tagFilter {
                Text("#\(tag) 태그가 붙은 사건이 모입니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            } else {
                #if os(iOS)
                Button { showingNewEvent = true } label: {
                    Label("사건 추가", systemImage: "plus")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 22).padding(.vertical, 13)
                        .background(Color.primary, in: Capsule())
                        .foregroundStyle(Palette.pageBackground)
                }
                .padding(.bottom, 8)
                #endif
            }
        }
        .sheet(item: $editingEvent) { event in
            EventEditorView(timeline: event.timeline ?? timeline, event: event) { saved in
                expanded = saved?.id
            }
        }
        .sheet(isPresented: $showingNewEvent) {
            EventEditorView(timeline: timeline, event: nil) { saved in
                expanded = saved?.id
            }
        }
        .sheet(isPresented: $showingSettings) {
            TimelineEditorView(timeline: timeline)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let tag = timeline.tagFilter {
            ContentUnavailableView {
                Label("#\(tag) 사건이 없어요", systemImage: "number")
            } description: {
                Text("이 태그를 사건에 달면 여기에 자동으로 모여요.")
            }
        } else {
            ContentUnavailableView {
                Label("아직 사건이 없어요", systemImage: "sparkles")
            } description: {
                Text("‘사건 추가’를 눌러 첫 순간을 남겨보세요.\n위에서 아래로 시간 순으로 쌓이고, 사이 간격은 실제로 흐른 시간만큼 벌어져요.")
            }
        }
    }
}
