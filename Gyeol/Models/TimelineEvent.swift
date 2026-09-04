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

    /// Raw value of `CardStyle`. Stored as a string so an unknown value from a future
    /// version degrades to the default instead of failing to load.
    var styleID: String = CardStyle.classic.rawValue

    /// Stored outside the SQLite file so large photos don't bloat the store.
    @Attribute(.externalStorage)
    var photoData: Data?

    var timeline: Timeline?

    init(
        date: Date,
        title: String,
        note: String = "",
        tags: [String] = [],
        style: CardStyle = .classic,
        photoData: Data? = nil
    ) {
        self.date = date
        self.title = title
        self.note = note
        self.tags = tags
        self.styleID = style.rawValue
        self.photoData = photoData
    }

    func hasTag(_ tag: String) -> Bool {
        tags.contains { Tag.matches($0, tag) }
    }
}

// Declared outside the class so the @Model macro leaves it alone.
extension TimelineEvent {
    var style: CardStyle {
        get { CardStyle(rawValue: styleID) ?? .classic }
        set { styleID = newValue.rawValue }
    }
}
