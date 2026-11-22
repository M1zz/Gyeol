import Foundation

extension Date {
    var yearLabel: String {
        String(AppLocale.calendar.component(.year, from: self))
    }

    /// "3월 5일" — the date printed on each node of the vertical timeline.
    var nodeDateLabel: String {
        let c = AppLocale.calendar.dateComponents([.month, .day], from: self)
        return String(localized: "\(c.month ?? 0)월 \(c.day ?? 0)일", locale: AppLocale.locale)
    }

    /// "5" — the oversized numeral the editorial card leads with.
    var dayNumber: String { String(AppLocale.calendar.component(.day, from: self)) }

    /// "3월" · "Mar" · "3月" — the month beside the oversized numeral, in the reader's language.
    var monthLabel: String { formatted(Date.FormatStyle(locale: AppLocale.locale, calendar: AppLocale.calendar).month(.abbreviated)) }

    /// "2019.03.05" — stamped on the film card like a date-back print.
    var stampLabel: String {
        let c = AppLocale.calendar.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d.%02d.%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

/// Spells out how much time actually passed between two events, so the gap on the
/// track is readable as a number and not only as a distance.
enum DurationLabel {
    static func between(_ earlier: Date, _ later: Date) -> String {
        let c = AppLocale.calendar.dateComponents([.year, .month, .day], from: earlier, to: later)
        let years = c.year ?? 0
        let months = c.month ?? 0
        let days = c.day ?? 0

        if years > 0 { return months > 0 ? String(localized: "\(years)년 \(months)개월", locale: AppLocale.locale) : String(localized: "\(years)년", locale: AppLocale.locale) }
        if months > 0 { return days > 0 ? String(localized: "\(months)개월 \(days)일", locale: AppLocale.locale) : String(localized: "\(months)개월", locale: AppLocale.locale) }
        if days > 0 { return String(localized: "\(days)일", locale: AppLocale.locale) }
        return String(localized: "같은 날")
    }
}
