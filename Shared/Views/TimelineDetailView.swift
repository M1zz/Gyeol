import SwiftUI
import SwiftData
import TipKit

struct TimelineDetailView: View {
    @Bindable var timeline: Timeline

    @Query private var allEvents: [TimelineEvent]
    @State private var expanded: PersistentIdentifier?
    @State private var editingEvent: TimelineEvent?
    @State private var showingNewEvent = false
    @State private var showingSettings = false
    @AppStorage(TimelineOrder.newestFirstKey) private var newestFirst = false
    @AppStorage(TimelineSpacing.evenKey) private var evenSpacing = false

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
        .safeAreaInset(edge: .top) {
            if !events.isEmpty {
                VStack(spacing: 8) {
                    TipView(ExpandCardTip())
                    TipView(TagTimelineTip())
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            if events.contains(where: { !$0.tags.isEmpty }) { TagTimelineTip.hasTaggedEvent = true }
        }
        .background(Palette.groupedBackground)
        #if DEBUG
        .onAppear {
            // 두 칸일 때 태그 장면 뒤에 깔린 타임라인은 데모 인자를 받지 않는다.
            guard ScreenshotDemo.isActive, ScreenshotDemo.screen != "tag" else { return }
            if let i = ScreenshotDemo.index("-demoExpand"), events.indices.contains(i) { expanded = events[i].id }
            if let i = ScreenshotDemo.index("-demoEdit"), events.indices.contains(i) {
                let event = events[i]
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { editingEvent = event }
            }
        }
        #endif
        .navigationTitle(timeline.name)
        .inlineNavigationTitle()
        .toolbar {
            #if os(macOS)
            ToolbarItem {
                if !timeline.isTagTimeline {
                    Button { showingNewEvent = true } label: {
                        Label("순간 추가", systemImage: "plus")
                    }
                }
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if !timeline.isTagTimeline {
                        Button { showingNewEvent = true } label: { Label("순간 추가", systemImage: "plus") }
                    }
                    Button { showingSettings = true } label: { Label("이름·색 바꾸기", systemImage: "paintpalette") }
                    if events.count > 1 {
                        Picker("정렬", selection: $newestFirst) {
                            Text("오래된 것부터").tag(false)
                            Text("최근 것부터").tag(true)
                        }
                        Picker("간격", selection: $evenSpacing) {
                            Text("흐른 시간만큼").tag(false)
                            Text("일정하게").tag(true)
                        }
                    }
                    // 기본 내보내기 — 어느 칸에서나 무료다. 메모 · 메일에 그대로 붙여 넣을 수 있는 글로.
                    if !events.isEmpty {
                        ShareLink(item: TimelineExport.text(name: timeline.name, events: events)) {
                            Label("텍스트로 내보내기", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(Text("더 보기"))
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let tag = timeline.tagFilter {
                Text("#\(tag) 태그가 붙은 순간이 모입니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            } else {
                #if os(iOS)
                Button { showingNewEvent = true } label: {
                    Label("순간 추가", systemImage: "plus")
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
                Label("#\(tag) 순간이 없어요", systemImage: "number")
            } description: {
                Text("이 태그를 순간에 달면 여기에 자동으로 모여요.")
            }
        } else {
            ContentUnavailableView {
                Label("아직 순간이 없어요", systemImage: "sparkles")
            } description: {
                Text("‘순간 추가’를 눌러 첫 순간을 남겨보세요.\n위에서 아래로 시간 순으로 쌓이고, 사이 간격은 실제로 흐른 시간만큼 벌어져요.")
            }
        }
    }
}
