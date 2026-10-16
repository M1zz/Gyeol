import AppIntents
import SwiftData
import Foundation

// 단축어 · Siri 로 "지금 이 순간"을 타임라인에 남긴다. 앱을 열지 않고 기록하는 것이 이 앱의 핵심 동작이다.
// 저장소는 앱 화면과 같은 AppContainer.shared — 열려 있는 화면에도 곧바로 나타나고 iCloud 로 이어진다.

/// 단축어에서 고를 수 있는 타임라인. 태그 타임라인은 사건을 직접 담지 않으므로 고를 수 없다.
struct TimelineEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "타임라인"
    static let defaultQuery = TimelineEntityQuery()

    /// SwiftData 의 PersistentIdentifier 를 JSON 으로 옮긴 문자열 — 실행이 바뀌어도 같은 타임라인을 가리킨다.
    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    init(_ timeline: Timeline) {
        id = TimelineEntity.encode(timeline.persistentModelID)
        name = timeline.name
    }

    static func encode(_ identifier: PersistentIdentifier) -> String {
        (try? JSONEncoder().encode(identifier)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}

struct TimelineEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [TimelineEntity] {
        let wanted = Set(identifiers)
        return try Self.ownTimelines().map(TimelineEntity.init).filter { wanted.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [TimelineEntity] {
        try Self.ownTimelines().map(TimelineEntity.init)
    }

    @MainActor
    static func ownTimelines() throws -> [Timeline] {
        let all = try AppContainer.shared.mainContext.fetch(
            FetchDescriptor<Timeline>(sortBy: [SortDescriptor(\.createdAt)])
        )
        return all.filter { !$0.isTagTimeline }
    }
}

struct AddEventIntent: AppIntent {
    static let title: LocalizedStringResource = "사건 기록하기"
    static let description = IntentDescription("고른 타임라인에 사건을 남겨요. 날짜를 정하지 않으면 지금 시각으로 기록해요.")

    @Parameter(title: "타임라인")
    var timeline: TimelineEntity

    @Parameter(title: "제목", requestValueDialog: "어떤 일이 있었나요?")
    var eventTitle: String

    @Parameter(title: "날짜")
    var date: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$timeline)에 \(\.$eventTitle) 기록하기") {
            \.$date
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw $eventTitle.needsValueError("어떤 일이 있었나요?")
        }
        guard let target = try TimelineEntityQuery.ownTimelines().first(where: {
            TimelineEntity.encode($0.persistentModelID) == timeline.id
        }) else {
            throw AddEventError.timelineMissing
        }

        let event = TimelineEvent(date: date ?? .now, title: title)
        target.add(event)
        try AppContainer.shared.mainContext.save()
        AppActivity.eventSaved(true)

        return .result(dialog: "‘\(target.name)’에 ‘\(title)’을(를) 남겼어요.")
    }
}

enum AddEventError: Error, CustomLocalizedStringResourceConvertible {
    case timelineMissing

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .timelineMissing: "그 타임라인을 찾지 못했어요. 지워졌거나 아직 이 기기로 넘어오지 않았을 수 있어요."
        }
    }
}

struct YeoulShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddEventIntent(),
            phrases: [
                "\(.applicationName)에 기록하기",
                "\(.applicationName)에 사건 남기기",
                "\(.applicationName)에 \(\.$timeline) 기록하기",
            ],
            shortTitle: "사건 기록하기",
            systemImageName: "calendar.badge.plus"
        )
    }
}
