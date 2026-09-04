import Foundation
import SwiftData
import SwiftUI

@Model
final class Timeline {
    var name: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TimelineEvent.timeline)
    var events: [TimelineEvent] = []

    init(name: String, colorHex: String, createdAt: Date = .now) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    /// Events are always presented in chronological order, regardless of insertion order.
    var sortedEvents: [TimelineEvent] {
        events.sorted { ($0.date, $0.title) < ($1.date, $1.title) }
    }

    var color: Color { Color(hex: colorHex) }
}

enum TimelinePalette {
    static let hexes = ["2E6B5E", "B3472B", "3A5BA0", "8A5A9E", "C08A1E", "4A4A4A"]
    static func next(after count: Int) -> String { hexes[count % hexes.count] }
}
