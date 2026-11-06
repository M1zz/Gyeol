import Foundation

/// 타임라인을 글로 옮긴다. 메모 · 메일 · 메시지에 그대로 붙여 넣을 수 있게. 어느 칸에서나 무료다.
///
///     우리 아이 첫 해
///
///     2024. 3. 1. — 태어난 날
///     오후 3시 12분, 3.2kg
///     #첫날
///
enum TimelineExport {
    static func text(name: String, events: [TimelineEvent]) -> String {
        let body = events.chronological.map { event -> String in
            var lines = ["\(event.date.formatted(date: .long, time: .omitted)) — \(event.title)"]
            let note = event.note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty { lines.append(note) }
            if !event.tags.isEmpty { lines.append(event.tags.map { "#\($0)" }.joined(separator: " ")) }
            return lines.joined(separator: "\n")
        }
        return ([name] + body).joined(separator: "\n\n") + "\n"
    }
}
