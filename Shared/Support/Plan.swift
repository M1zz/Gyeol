//
//  Plan.swift
//
//  여울의 칸(무료 · Plus · Pro)과 칸마다 여는 것. **무엇이 어느 칸인지는 여기 한 곳에만 적는다.**
//
//   · 무료: 타임라인 2개 · 사건 · 사진 · 이야기 무제한 · 그날 사진 찾기 · 해시태그 모아 보기 ·
//           카드 디자인 기본 · 포스터 · 텍스트로 내보내기 · 이 기기에 저장
//   · Plus: 타임라인 무제한 · 해시태그 타임라인 저장 · 카드 디자인 네 가지 전부
//   · Pro:  Plus 전부 + iCloud 동기화(iPhone · iPad · Mac) · Siri · 단축어로 사건 추가
//
//  ⚠️ 이미 만든 타임라인 · 카드 · 저장한 태그 타임라인은 칸과 상관없이 보고 고치고 지운다.
//     한도는 **새로 만드는 것**만 본다.
//
//  StoreKit · LeeoKit 은 여기 없다. 이 파일은 맥 타깃(YeoulMac)과 시험 번들도 함께 컴파일한다 —
//  둘 다 LeeoKit 이 없다. 영수증을 읽는 쪽은 iOS 타깃의 `Gyeol/Store/` 이고, 화면은
//  환경값 `planAccess` 로 지금 칸과 페이월을 받는다. 맥은 기본값(모두 열림)을 쓴다.
//

import SwiftUI

/// 칸. 값이 클수록 더 많이 연다. Pro 는 Plus 를 전부 포함한다.
enum PlanTier: Int, Comparable, CaseIterable {
    case free = 0
    case plus = 1
    case pro = 2

    static func < (lhs: PlanTier, rhs: PlanTier) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// 값을 받고 여는 것. 페이월 · 비교표 · 잠긴 자리가 이 목록 하나를 함께 읽는다.
enum PlanFeature: String, CaseIterable, Identifiable {
    case moreTimelines
    case tagTimelines
    case cardStyles
    case iCloudSync
    case siri

    var id: String { rawValue }

    /// 이 기능을 여는 가장 낮은 칸.
    var tier: PlanTier {
        switch self {
        case .moreTimelines, .tagTimelines, .cardStyles: .plus
        case .iCloudSync, .siri:                          .pro
        }
    }

    /// 그 칸에서 새로 열리는 것 (페이월 카드 차례).
    static func opened(by tier: PlanTier) -> [PlanFeature] { allCases.filter { $0.tier == tier } }

    // MARK: 무료 한도

    /// 무료로 만들 수 있는 타임라인 수 (태그 타임라인은 세지 않는다 — 그건 Plus 기능이다).
    static let freeTimelineLimit = 2

    /// 무료로 고를 수 있는 카드 디자인.
    static let freeCardStyles: Set<CardStyle> = [.classic, .poster]
}

/// 화면이 받는 지금 칸과 페이월.
struct PlanAccess {
    var tier: PlanTier
    /// 잠긴 기능을 앞세운 페이월. 부딪힌 자리에서 시트로 띄운다(시트 위에서도 뜨게).
    var paywall: (PlanFeature) -> AnyView

    func allows(_ feature: PlanFeature) -> Bool { tier >= feature.tier }

    /// 새 타임라인을 하나 더 만들어도 되는가. `count` 는 지금 있는 (태그가 아닌) 타임라인 수.
    func canCreateTimeline(having count: Int) -> Bool {
        allows(.moreTimelines) || count < PlanFeature.freeTimelineLimit
    }

    /// 이 카드 디자인을 고를 수 있는가. 이미 그 디자인인 카드는 칸과 상관없이 그대로 둔다.
    func canPick(_ style: CardStyle, current: CardStyle? = nil) -> Bool {
        allows(.cardStyles) || PlanFeature.freeCardStyles.contains(style) || style == current
    }

    /// 맥 · 미리보기 · 시험: 파는 곳이 없으니 모두 열려 있다.
    static let unlocked = PlanAccess(tier: .pro, paywall: { _ in AnyView(EmptyView()) })
}

extension EnvironmentValues {
    @Entry var planAccess: PlanAccess = .unlocked
}

/// 잠긴 줄 · 카드에 붙는 작은 자물쇠. 눌러 보기 전에 잠긴 걸 알 수 있게.
struct PlanLockBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityLabel(Text("잠김"))
    }
}
