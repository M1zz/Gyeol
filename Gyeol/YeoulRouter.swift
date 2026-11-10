import SwiftData
import Observation

/// 앱 화면으로 넘기는 요청. 목록 화면이 그 타임라인을 열고 비운다.
/// 맥 타깃(YeoulMac)도 함께 컴파일한다 — 페이월을 띄우는 자리(`PlanRoot`)가 이것을 본다.
@MainActor @Observable
final class YeoulRouter {
    static let shared = YeoulRouter()
    var timelineID: PersistentIdentifier?
    /// Siri · 단축어가 잠긴 기능을 찾아 앱을 열었을 때 띄울 페이월 (→ Store/PlanRoot.swift).
    var paywall: PlanFeature?
}
