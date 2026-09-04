import Foundation

extension Date {
    /// "9.3" style label used in list subtitles.
    var monthDayLabel: String {
        let c = Calendar.current.dateComponents([.month, .day], from: self)
        return "\(c.month ?? 0).\(c.day ?? 0)"
    }

    var yearLabel: String {
        String(Calendar.current.component(.year, from: self))
    }

    /// "3월 5일" — the date printed on each node of the vertical timeline.
    var nodeDateLabel: String {
        let c = Calendar.current.dateComponents([.month, .day], from: self)
        return "\(c.month ?? 0)월 \(c.day ?? 0)일"
    }

    /// "5" — the oversized numeral the editorial card leads with.
    var dayNumber: String { String(Calendar.current.component(.day, from: self)) }

    /// "3월"
    var monthLabel: String { "\(Calendar.current.component(.month, from: self))월" }

    /// "2019.03.05" — stamped on the film card like a date-back print.
    var stampLabel: String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d.%02d.%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

/// Spells out how much time actually passed between two events, so the gap on the
/// track is readable as a number and not only as a distance.
enum DurationLabel {
    static func between(_ earlier: Date, _ later: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: earlier, to: later)
        let years = c.year ?? 0
        let months = c.month ?? 0
        let days = c.day ?? 0

        if years > 0 { return months > 0 ? "\(years)년 \(months)개월" : "\(years)년" }
        if months > 0 { return days > 0 ? "\(months)개월 \(days)일" : "\(months)개월" }
        if days > 0 { return "\(days)일" }
        return "같은 날"
    }
}
