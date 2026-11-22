import SwiftUI

/// 숫자와 날짜를 한 모양으로 쓰기 위한 로케일 · 달력.
///
/// 아랍어에서는 기기 설정에 따라 숫자가 ١٢٣ 과 123 으로 섞이고, 날짜가 히즈라력으로 나올 수 있다.
/// 타임라인의 날짜 · 간격 · 필름 도장이 서로 다른 모양이 되지 않게, 아랍어일 때만 0-9 숫자와 양력으로 맞춘다.
/// 다른 언어는 기기 설정 그대로다 (태국어의 불기 같은 것을 건드리지 않는다).
enum AppLocale {
    static let isArabic = Bundle.main.preferredLocalizations.first == "ar"

    static let locale: Locale = {
        guard isArabic else { return .autoupdatingCurrent }
        var parts = Locale.Components(locale: .current)
        parts.numberingSystem = "latn"
        parts.calendar = .gregorian
        return Locale(components: parts)
    }()

    static let calendar: Calendar = {
        guard isArabic else { return .autoupdatingCurrent }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    /// 타임라인 그림. 아랍어에서는 척추선이 오른쪽에 서므로 그림도 그쪽을 쓴다 (이 기호는 저절로 뒤집히지 않는다).
    static let timelineSymbol = isArabic ? "calendar.day.timeline.right" : "calendar.day.timeline.left"

    /// `date.formatted(date:time:)` 과 같은 모양을, 위의 로케일 · 달력으로.
    static func dateStyle(_ date: Date.FormatStyle.DateStyle) -> Date.FormatStyle {
        Date.FormatStyle(date: date, time: .omitted, locale: locale, calendar: calendar)
    }
}

extension String {
    /// 고정폭 글꼴에는 아랍 글자가 없어 글자가 이어지지 않고 끊긴다. 그런 글은 기본 글꼴로 쓴다.
    var hasArabicScript: Bool {
        unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) || (0x0750...0x077F).contains($0.value)
            || (0x08A0...0x08FF).contains($0.value) || (0xFB50...0xFDFF).contains($0.value) || (0xFE70...0xFEFF).contains($0.value) }
    }
}

extension View {
    /// 앱 맨 위에 한 번. 시트도 이 값을 물려받는다.
    func appLocale() -> some View {
        #if os(macOS)
        // 맥은 아랍어로 띄워도 왼쪽부터 놓일 때가 있어 방향도 정한다.
        environment(\.locale, AppLocale.locale)
            .environment(\.calendar, AppLocale.calendar)
            .environment(\.layoutDirection, AppLocale.isArabic ? .rightToLeft : .leftToRight)
        #else
        environment(\.locale, AppLocale.locale)
            .environment(\.calendar, AppLocale.calendar)
        #endif
    }
}
