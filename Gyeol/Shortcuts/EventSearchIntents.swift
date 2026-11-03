import AppIntents
import CoreSpotlight
import SwiftData
import Foundation

// 지난 기록을 Siri · Spotlight 가 찾게 한다.
//  - Spotlight: 사건마다 제목 · 메모 · 태그 · 날짜를 싣는다(iOS 18+). 누르면 그 타임라인이 열린다.
//  - "여울 이맘때": 지난해들의 오늘 앞뒤 사흘에 남긴 일을 알려 준다.
// 저장소는 AddEventIntent 와 같은 AppContainer.shared.

/// 앱 화면으로 넘기는 요청. 목록 화면이 그 타임라인을 열고 비운다.
@MainActor @Observable
final class YeoulRouter {
    static let shared = YeoulRouter()
    var timelineID: PersistentIdentifier?
}

struct EventEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "기록"
    static let defaultQuery = EventEntityQuery()

    let id: String
    let title: String
    let note: String
    let tags: [String]
    let date: Date
    let timelineName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(date.formatted(date: .abbreviated, time: .omitted)) · \(timelineName)"
        )
    }

    init(_ event: TimelineEvent) {
        id = TimelineEntity.encode(event.persistentModelID)
        title = event.title
        note = event.note
        tags = event.tags
        date = event.date
        timelineName = event.timeline?.name ?? ""
    }
}

@available(iOS 18.0, *)
extension EventEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.textContent = note
        set.keywords = tags + [timelineName]
        set.contentCreationDate = date
        return set
    }
}

struct EventEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [EventEntity] {
        let wanted = Set(identifiers)
        return try Self.allEvents().map(EventEntity.init).filter { wanted.contains($0.id) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [EventEntity] {
        try Self.allEvents()
            .filter { $0.title.localizedCaseInsensitiveContains(string) || $0.note.localizedCaseInsensitiveContains(string) }
            .map(EventEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [EventEntity] {
        try Self.allEvents().prefix(20).map(EventEntity.init)
    }

    /// 최근 것부터. 태그 타임라인은 사건을 담지 않으므로 사건만 읽으면 겹치지 않는다.
    @MainActor
    static func allEvents() throws -> [TimelineEvent] {
        try AppContainer.shared.mainContext.fetch(
            FetchDescriptor<TimelineEvent>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        )
    }

    /// Spotlight 에 싣는 기록을 지금 것에 맞춘다. 앱을 열 때와 뒤로 보낼 때 부른다.
    @MainActor
    static func reindex() async {
        guard #available(iOS 18.0, *) else { return }
        let entities = ((try? allEvents()) ?? []).filter { !$0.title.isEmpty }.map(EventEntity.init)
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: EventEntity.self)
        try? await index.indexAppEntities(entities)
    }
}

/// 지난해들의 오늘 앞뒤 사흘에 남긴 일.
struct OnThisDayIntent: AppIntent {
    static let title: LocalizedStringResource = "이맘때 기록"
    static let description = IntentDescription("지난해 이맘때 남긴 기록을 찾아 알려 줘요.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[EventEntity]> & ProvidesDialog {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let thisYear = calendar.component(.year, from: today)
        let found = try EventEntityQuery.allEvents().filter { event in
            let year = calendar.component(.year, from: event.date)
            guard year < thisYear,
                  let sameDay = calendar.date(byAdding: .year, value: thisYear - year, to: calendar.startOfDay(for: event.date)),
                  let days = calendar.dateComponents([.day], from: today, to: sameDay).day else { return false }
            return abs(days) <= 3
        }
        guard let latest = found.first else {
            return .result(value: [], dialog: "지난해 이맘때 남긴 기록이 없어요.")
        }
        let yearsAgo = thisYear - calendar.component(.year, from: latest.date)
        return .result(
            value: found.map(EventEntity.init),
            dialog: "\(yearsAgo)년 전 이맘때, ‘\(latest.title)’을(를) 남겼어요."
        )
    }
}

/// 기록이 든 타임라인을 연다. Spotlight · Siri 결과를 누르면 여기로 온다.
struct OpenEventIntent: OpenIntent {
    static let title: LocalizedStringResource = "기록 열기"

    @Parameter(title: "기록")
    var target: EventEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        let event = try EventEntityQuery.allEvents().first { TimelineEntity.encode($0.persistentModelID) == target.id }
        YeoulRouter.shared.timelineID = event?.timeline?.persistentModelID
        return .result()
    }
}
