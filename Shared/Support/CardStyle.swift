import Foundation

/// How a milestone card is dressed. Picked per card in the editor.
enum CardStyle: String, CaseIterable, Identifiable {
    /// Text-led card with the photo underneath — the original look.
    case classic
    /// Photo fills the card; the title sits on it in large serif.
    case poster
    /// Print-like: photo in a matte, typewriter caption below.
    case film
    /// No photo emphasis — an oversized date and serif text carry the card.
    case editorial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: String(localized: "기본")
        case .poster: String(localized: "포스터")
        case .film: String(localized: "필름")
        case .editorial: String(localized: "여백")
        }
    }

    var blurb: String {
        switch self {
        case .classic: String(localized: "글이 중심, 사진은 아래")
        case .poster: String(localized: "사진을 꽉 채우고 글을 얹어요")
        case .film: String(localized: "인화지처럼 여백을 두른 사진")
        case .editorial: String(localized: "날짜와 글씨가 주인공")
        }
    }
}
