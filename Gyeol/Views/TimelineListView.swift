import SwiftUI
import SwiftData

struct TimelineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Timeline.createdAt) private var timelines: [Timeline]
    @Query private var allEvents: [TimelineEvent]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if timelines.isEmpty {
                    ContentUnavailableView {
                        Label("타임라인이 없어요", systemImage: "calendar.day.timeline.left")
                    } description: {
                        Text("첫 타임라인을 만들어보세요.\n아이의 첫 해, 앱 출시 기록, 여행 — 무엇이든 좋아요.")
                    } actions: {
                        Button("새 타임라인") { showingNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(timelines) { timeline in
                            NavigationLink(value: timeline) {
                                TimelineRow(timeline: timeline, events: events(of: timeline))
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("여울")
            .navigationDestination(for: Timeline.self) { TimelineDetailView(timeline: $0) }
            .navigationDestination(for: TagRoute.self) { TagTimelineView(tag: $0.tag) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("새 타임라인")
                }
            }
            .sheet(isPresented: $showingNew) {
                TimelineEditorView(timeline: nil)
            }
        }
    }

    private func events(of timeline: Timeline) -> [TimelineEvent] {
        guard let tag = timeline.tagFilter else { return timeline.sortedEvents }
        return allEvents.filter { $0.hasTag(tag) }.chronological
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(timelines[index]) }
    }
}

private struct TimelineRow: View {
    let timeline: Timeline
    let events: [TimelineEvent]

    var body: some View {
        HStack(spacing: 14) {
            marker
            VStack(alignment: .leading, spacing: 3) {
                Text(timeline.name).font(.body.weight(.medium))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var marker: some View {
        if timeline.isTagTimeline {
            Image(systemName: "number")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(timeline.color)
                .frame(width: 12, height: 12)
        } else {
            Circle().fill(timeline.color).frame(width: 12, height: 12)
        }
    }

    private var subtitle: String {
        let kind = timeline.isTagTimeline ? "태그 타임라인 · " : ""
        guard let last = events.last else { return kind + "사건 없음" }
        return kind + "사건 \(events.count)개 · 마지막 \(last.date.yearLabel).\(last.date.monthDayLabel)"
    }
}

#Preview {
    TimelineListView()
        .modelContainer(for: [Timeline.self, TimelineEvent.self], inMemory: true)
}
