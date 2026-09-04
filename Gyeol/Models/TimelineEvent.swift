import Foundation
import SwiftData

@Model
final class TimelineEvent {
    var date: Date
    var title: String
    var note: String

    /// Free-form labels. Tapping one anywhere in the app rebuilds a timeline out of every
    /// milestone that shares it.
    var tags: [String] = []

    /// Stored outside the SQLite file so large photos don't bloat the store.
    @Attribute(.externalStorage)
    var photoData: Data?

    var timeline: Timeline?

    init(date: Date, title: String, note: String = "", tags: [String] = [], photoData: Data? = nil) {
        self.date = date
        self.title = title
        self.note = note
        self.tags = tags
        self.photoData = photoData
    }

    func hasTag(_ tag: String) -> Bool {
        tags.contains { Tag.matches($0, tag) }
    }
}
