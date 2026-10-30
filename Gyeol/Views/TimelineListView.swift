import SwiftUI
import SwiftData
import LeeoKit

/// 남긴 사건이 이만큼 쌓였을 때 응원을 부탁한다. 큰 것부터.
enum YeoulTipMoments {
    static let events = [300, 100, 30]

    static func reached(events total: Int) -> [LeeoTipMoment] {
        events.filter { total >= $0 }.map { threshold in
            LeeoTipMoment(id: "events.\(threshold)",
                          message: String(localized: "지금까지 사건 \(total)개를 기록했어요",
                                          comment: "Tip ask card: total number of events recorded across all timelines"))
        }
    }
}

struct TimelineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Timeline.createdAt) private var timelines: [Timeline]
    @Query private var allEvents: [TimelineEvent]
    @State private var showingNew = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false
    @State private var path = NavigationPath()
    @AppStorage(YeoulOnboardingView.seenKey) private var hasSeenOnboarding = false
    // 아이폰 듀오: 펴면 왼쪽(세로면 아래) 목록 | 오른쪽(위) 고른 타임라인 (LeeoKit Fold)
    @Environment(\.foldLayout) private var fold
    /// 펼친 화면에서 오른쪽에 세운 타임라인. 목록에서 열면 여기 남아, 펴고 접어도 그 타임라인이 이어진다.
    @State private var opened: Timeline?

    var body: some View {
        // 접혀 있거나 보통 아이폰이면 목록만 그린다. 지금 화면 그대로다.
        FoldSplitView {
            list
        } result: {
            openedPane
                .environment(\.foldLayout, .single)
        }
        .onChange(of: fold.isUnfolded) { _, unfolded in carryOpened(unfolded: unfolded) }
    }

    private var list: some View {
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
                        // 사건을 남기고 돌아온 자리. 쌓인 기록이 숫자로 보일 때만, 드물게 응원을 부탁한다.
                        LeeoTipAskSlot<YeoulSpec>(tipJar: YeoulSpec.tipJar,
                                                  reached: YeoulTipMoments.reached(events: allEvents.count))
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        ForEach(timelines) { timeline in
                            if fold.isUnfolded {
                                // 펼친 화면: 밀어 넣지 않고 오른쪽 판에 연다.
                                Button { opened = timeline } label: {
                                    TimelineRow(timeline: timeline, events: events(of: timeline))
                                }
                                .tint(.primary)
                                .listRowBackground(timeline == shownTimeline ? Color.accentColor.opacity(0.15) : nil)
                                .accessibilityAddTraits(timeline == shownTimeline ? .isSelected : [])
                            } else {
                                NavigationLink(value: timeline) {
                                    TimelineRow(timeline: timeline, events: events(of: timeline))
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("여울")
            .navigationDestination(for: Timeline.self) { timeline in
                TimelineDetailView(timeline: timeline)
                    .onAppear { opened = timeline }
            }
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

    // MARK: - 아이폰 듀오

    /// 오른쪽 판에 서는 타임라인. 아직 연 것이 없으면 맥처럼 첫 타임라인을 보여 준다. 빈 판으로 두지 않는다.
    private var shownTimeline: Timeline? {
        if let opened, timelines.contains(opened) { return opened }
        return timelines.first
    }

    @ViewBuilder
    private var openedPane: some View {
        NavigationStack {
            Group {
                if let shownTimeline {
                    TimelineDetailView(timeline: shownTimeline)
                        .id(shownTimeline.persistentModelID)
                } else {
                    ContentUnavailableView {
                        Label("타임라인이 없어요", systemImage: "calendar.day.timeline.left")
                    } description: {
                        Text("첫 타임라인을 만들어보세요.\n아이의 첫 해, 앱 출시 기록, 여행 — 무엇이든 좋아요.")
                    }
                }
            }
            .navigationDestination(for: TagRoute.self) { TagTimelineView(tag: $0.tag) }
        }
    }

    /// 펴고 접어도 보던 타임라인이 이어지게 한다.
    /// 펴면: 목록에서 타임라인 하나를 열어 둔 상태였으면 그걸 오른쪽 판으로 옮기고 왼쪽은 목록으로 돌아온다.
    /// 접으면: 오른쪽 판에서 보던 타임라인을 목록 위에 열어 둔다.
    private func carryOpened(unfolded: Bool) {
        if unfolded {
            if path.count == 1, opened != nil { path = NavigationPath() }
        } else if path.isEmpty, let opened, timelines.contains(opened) {
            path.append(opened)
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
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var marker: some View {
        if timeline.isTagTimeline {
            Image(systemName: "number")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(timeline.color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
        } else {
            Circle().fill(timeline.color).frame(width: 12, height: 12)
                .accessibilityHidden(true)
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
