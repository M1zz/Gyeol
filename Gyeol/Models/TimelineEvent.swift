import Foundation
import SwiftData

@Model
final class TimelineEvent {
    var date: Date
    var title: String
    var note: String

    /// Stored outside the SQLite file so large photos don't bloat the store.
    @Attribute(.externalStorage)
    var photoData: Data?

    var timeline: Timeline?

    init(date: Date, title: String, note: String = "", photoData: Data? = nil) {
        self.date = date
        self.title = title
        self.note = note
        self.photoData = photoData
    }
}
