import SwiftUI
import SwiftData

struct TimelineDetailView: View {
    @Bindable var timeline: Timeline

    @State private var expanded: PersistentIdentifier?
    @State private var editingEvent: TimelineEvent?
    @State private var showingNewEvent = false
    @State private var showingSettings = false

    private var events: [TimelineEvent] { timeline.sortedEvents }

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
        .background(Color(.systemGroupedBackground))
        .navigationTitle(timeline.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingNewEvent = true } label: { Label("사건 추가", systemImage: "plus") }
                    Button { showingSettings = true } label: { Label("이름·색 바꾸기", systemImage: "paintpalette") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button { showingNewEvent = true } label: {
                Label("사건 추가", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 22).padding(.vertical, 13)
                    .background(Color.primary, in: Capsule())
                    .foregroundStyle(Color(.systemBackground))
            }
            .padding(.bottom, 8)
        }
        .sheet(item: $editingEvent) { event in
            EventEditorView(timeline: timeline, event: event) { saved in
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

    private var emptyState: some View {
        ContentUnavailableView {
            Label("아직 사건이 없어요", systemImage: "sparkles")
        } description: {
            Text("‘사건 추가’를 눌러 첫 순간을 남겨보세요.\n위에서 아래로 시간 순으로 쌓이고, 사이 간격은 실제로 흐른 시간만큼 벌어져요.")
        }
    }
}
