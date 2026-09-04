import SwiftUI
import SwiftData

struct TimelineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Timeline.createdAt) private var timelines: [Timeline]
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
                                TimelineRow(timeline: timeline)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("결")
            .navigationDestination(for: Timeline.self) { TimelineDetailView(timeline: $0) }
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

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(timelines[index]) }
    }
}

private struct TimelineRow: View {
    let timeline: Timeline

    var body: some View {
        HStack(spacing: 14) {
            Circle().fill(timeline.color).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(timeline.name).font(.body.weight(.medium))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let count = timeline.events.count
        guard let last = timeline.sortedEvents.last else { return "사건 없음" }
        return "사건 \(count)개 · 마지막 \(last.date.yearLabel).\(last.date.monthDayLabel)"
    }
}

#Preview {
    TimelineListView()
        .modelContainer(for: [Timeline.self, TimelineEvent.self], inMemory: true)
}
