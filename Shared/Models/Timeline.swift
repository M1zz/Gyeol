import Foundation
import SwiftData
import SwiftUI

@Model
final class Timeline {
    // CloudKit requires a default on every non-optional attribute.
    var name: String = ""
    var colorHex: String = TimelinePalette.hexes[0]
    var createdAt: Date = Date.now

    /// When set, this timeline is a saved *view* rather than a container: it shows every
    /// event carrying this tag, wherever that event actually lives. Its own `events` stay
    /// empty, so deleting it never takes anyone's milestones with it.
    var tagFilter: String?

    /// Optional because CloudKit refuses to sync a non-optional relationship.
    @Relationship(deleteRule: .cascade, inverse: \TimelineEvent.timeline)
    var events: [TimelineEvent]?

    init(name: String, colorHex: String, createdAt: Date = .now, tagFilter: String? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.tagFilter = tagFilter
    }

    var isTagTimeline: Bool { tagFilter != nil }

    var sortedEvents: [TimelineEvent] { (events ?? []).chronological }

    func add(_ event: TimelineEvent) {
        if events == nil { events = [] }
        events?.append(event)
    }

    var color: Color { .adaptive(hex: colorHex) }
}

extension Array where Element == TimelineEvent {
    /// Events are always presented in chronological order, regardless of where they came from.
    var chronological: [TimelineEvent] {
        sorted { ($0.date, $0.title) < ($1.date, $1.title) }
    }
}

enum TimelinePalette {
    static let hexes = ["2E6B5E", "B3472B", "3A5BA0", "8A5A9E", "C08A1E", "4A4A4A"]

    static func next(after count: Int) -> String { hexes[abs(count) % hexes.count] }

    /// 색 고르기에서 VoiceOver·음성 명령이 부를 이름
    static func name(for hex: String) -> String {
        switch hex {
        case "2E6B5E": String(localized: "초록")
        case "B3472B": String(localized: "빨강")
        case "3A5BA0": String(localized: "파랑")
        case "8A5A9E": String(localized: "보라")
        case "C08A1E": String(localized: "노랑")
        default: String(localized: "회색")
        }
    }

    /// A stable colour for an unsaved tag view. `hashValue` is seeded per process, so it
    /// would hand the same tag a different colour on every launch.
    static func forTag(_ tag: String) -> String {
        let key = tag.lowercased().unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return hexes[key % hexes.count]
    }
}
