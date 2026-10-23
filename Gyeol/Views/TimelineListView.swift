import SwiftUI
import SwiftData

struct TimelineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Timeline.createdAt) private var timelines: [Timeline]
    @Query private var allEvents: [TimelineEvent]
    @State private var showingNew = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false
    @State private var path = NavigationPath()
    @AppStorage(YeoulOnboardingView.seenKey) private var hasSeenOnboarding = false

    var body: some View {
        NavigationStack(path: $path) {
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
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("설정")
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("새 타임라인")
                }
            }
            .sheet(isPresented: $showingNew) {
                TimelineEditorView(timeline: nil)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingOnboarding) {
                YeoulOnboardingView()
            }
            .onAppear(perform: presentOnboardingIfNeeded)
            #if DEBUG
            .onAppear(perform: openDemoScreen)
            #endif
        }
    }

    /// 처음 여는 사람에게만 안내를 띄운다. 이미 기록이 있는 사람(이 안내가 생기기 전부터 쓰던 사람)은
    /// 앱을 알고 있으니 띄우지 않고 본 것으로 둔다 — 안내는 설정에서 언제든 다시 열 수 있다.
    private func presentOnboardingIfNeeded() {
        guard !hasSeenOnboarding else { return }
        if timelines.isEmpty {
            showingOnboarding = true
        } else {
            hasSeenOnboarding = true
        }
    }

    #if DEBUG
    /// 스토어 스크린샷이 찍을 화면으로 곧장 간다.
    private func openDemoScreen() {
        guard ScreenshotDemo.isActive, path.isEmpty else { return }
        switch ScreenshotDemo.screen {
        case "trip":
            if let i = ScreenshotDemo.index("-demoTimeline"), timelines.indices.contains(i) { path.append(timelines[i]) }
        case "tag":
            if let tag = ScreenshotDemo.value("-demoTag") { path.append(TagRoute(tag: tag)) }
        default:
            break
        }
    }
    #endif

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
        let kind = timeline.isTagTimeline ? String(localized: "태그 타임라인 · ") : ""
        guard let last = events.last else { return kind + String(localized: "사건 없음") }
        return kind + String(localized: "사건 \(events.count)개 · 마지막 \(last.date.formatted(date: .numeric, time: .omitted))")
    }
}

#Preview {
    TimelineListView()
        .modelContainer(for: [Timeline.self, TimelineEvent.self], inMemory: true)
}
