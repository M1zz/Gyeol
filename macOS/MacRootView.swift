import SwiftUI
import SwiftData

/// The Mac shell: timelines in a sidebar, the selected one filling the rest of the
/// window. Same records as the phone, just with room to see them.
struct MacRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Timeline.createdAt) private var timelines: [Timeline]
    @Query private var allEvents: [TimelineEvent]

    @State private var selection: Timeline?
    @State private var tagRoute: TagRoute?
    @State private var showingNewTimeline = false
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .sheet(isPresented: $showingNewTimeline) {
            TimelineEditorView(timeline: nil)
        }
        .sheet(isPresented: $showingSettings) {
            if let selection {
                TimelineEditorView(timeline: selection)
            }
        }
        .onAppear { selectFirstIfNeeded() }
        // Records can arrive after the first render — from iCloud, or from another
        // window — so pick one up whenever the list changes too.
        .onChange(of: timelines.count) { _, _ in selectFirstIfNeeded() }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            Section("타임라인") {
                ForEach(timelines.filter { !$0.isTagTimeline }) { timeline in
                    row(timeline).tag(timeline)
                }
                .onDelete { delete(timelines.filter { !$0.isTagTimeline }, at: $0) }
            }
            let tagTimelines = timelines.filter(\.isTagTimeline)
            if !tagTimelines.isEmpty {
                Section("태그 타임라인") {
                    ForEach(tagTimelines) { timeline in
                        row(timeline).tag(timeline)
                    }
                    .onDelete { delete(tagTimelines, at: $0) }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 340)
        .toolbar {
            ToolbarItem {
                Button {
                    showingNewTimeline = true
                } label: {
                    Label("새 타임라인", systemImage: "plus")
                }
            }
        }
    }

    private func row(_ timeline: Timeline) -> some View {
        HStack(spacing: 10) {
            if timeline.isTagTimeline {
                Image(systemName: "number")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(timeline.color)
                    .frame(width: 12)
            } else {
                Circle().fill(timeline.color).frame(width: 10, height: 10).frame(width: 12)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(timeline.name)
                Text("사건 \(events(of: timeline).count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        NavigationStack {
            Group {
                if let selection {
                    TimelineDetailView(timeline: selection)
                } else {
                    ContentUnavailableView {
                        Label("타임라인을 골라주세요", systemImage: "sidebar.left")
                    } description: {
                        Text("왼쪽에서 타임라인을 고르거나 새로 만들어보세요.")
                    }
                }
            }
            .navigationDestination(for: TagRoute.self) { TagTimelineView(tag: $0.tag) }
        }
        .frame(minWidth: 520)
    }

    private func selectFirstIfNeeded() {
        if selection == nil { selection = timelines.first }
    }

    // MARK: Data

    private func events(of timeline: Timeline) -> [TimelineEvent] {
        guard let tag = timeline.tagFilter else { return timeline.sortedEvents }
        return allEvents.filter { $0.hasTag(tag) }.chronological
    }

    private func delete(_ list: [Timeline], at offsets: IndexSet) {
        for index in offsets {
            if selection == list[index] { selection = nil }
            context.delete(list[index])
        }
    }
}
