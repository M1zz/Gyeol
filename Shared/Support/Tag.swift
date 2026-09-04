import Foundation

enum Tag {
    /// Turns raw input into a storable tag, or nil when nothing usable is left.
    /// Leading "#" and any inner whitespace are dropped so "# 첫 걸음" and "첫걸음" agree.
    static func normalize(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasPrefix("#") { value.removeFirst() }
        value = value.components(separatedBy: .whitespacesAndNewlines).joined()
        return value.isEmpty ? nil : value
    }

    /// Compared case-insensitively so the same tag typed on two cards still lines up.
    static func matches(_ lhs: String, _ rhs: String) -> Bool {
        lhs.lowercased() == rhs.lowercased()
    }
}
