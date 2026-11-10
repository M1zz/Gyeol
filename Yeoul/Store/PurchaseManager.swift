//
//  PurchaseManager.swift
//  Yeoul
//
//  Plus · Pro 를 파는 자리. **속은 전부 `LeeoStore` 다.**
//  상품 로드 · 구매 · 복원 · 거래 리스너(다른 기기, 가족 공유, 구입 요청 승인, 환불, 만료)는 LeeoStore 안에 있다.
//  여기는 그 값을 SwiftUI `@Observable` 로 옮기고 앱의 칸(`PlanTier`)으로 바꿀 뿐이다.
//

import Foundation
import Combine
import StoreKit
import SwiftUI
import LeeoKit

@MainActor
@Observable
final class PurchaseManager {

    static let shared = PurchaseManager()

    @ObservationIgnored let store: LeeoStore

    /// 지금 쓰는 칸. 화면은 이 값(과 `access`)만 본다.
    private(set) var tier: PlanTier = ProEntitlement.tier
    /// 페이월에 설 상품들. 스토어에 아직 없는 상품은 여기 없다.
    private(set) var products: [Product] = []
    /// 이 Apple 계정이 가진 권한 상품들.
    private(set) var ownedProductIDs: Set<String> = []
    /// 지금 살아 있는 연 구독.
    private(set) var subscription: LeeoGraduation.Subscription?
    /// 페이월 전부터 쓰던 분이라 Pro 평생인가.
    private(set) var isGrandfathered = false
    private(set) var isWorking = false
    private(set) var failureMessage: String?

    /// 이번 실행에서 영수증을 실제로 읽었는가. 읽기 전에는 캐시에 '무료'를 적지 않는다.
    @ObservationIgnored private var entitlementsChecked = false
    @ObservationIgnored private var observation: AnyCancellable?

    private init() {
        guard let config = YeoulSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. YeoulSpec.monetization 을 확인할 것")
        }
        store = LeeoStore(config: config, grandfather: { await Self.isGrandfathered() })
        // objectWillChange 는 값이 바뀌기 직전에 온다. 다음 차례로 미뤄 읽는다.
        observation = store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.pull() }
        }
        // 지난번에 확인한 권한(LeeoStore 캐시)으로 바로 시작한다. 산 분이 잠깐 '무료'로 보이지 않게.
        pull()
    }

    /// 개발자 응원 팁. 결제 리스너를 스토어와 함께 쓴다(따로 돌면 팁 결제를 스토어가 먼저 끝내 버린다).
    var tipJar: LeeoTipJar {
        guard let tipJar = store.tipJar else { preconditionFailure("계약에 팁이 없다. YeoulSpec.monetization 을 확인할 것") }
        return tipJar
    }

    func allows(_ feature: PlanFeature) -> Bool { tier >= feature.tier }

    func ownsLifetime(_ tier: PlanTier) -> Bool { ProEntitlement.ownsLifetime(tier, in: ownedProductIDs) }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    func owns(_ productID: String) -> Bool { ownedProductIDs.contains(productID) }

    /// 지금 살아 있는 자동 갱신 구독이 있는가(주 · 월 · 연). 있으면 설정에 '구독 관리'가 선다.
    var hasSubscription: Bool { !ownedProductIDs.isDisjoint(with: ProEntitlement.subscriptionIDs) }

    /// 산 칸 (페이월 전부터 쓰던 분은 Pro). 상품을 아직 못 본 기기에서 열어 둔 것(`tier`)과 다르다 —
    /// 설정 · 페이월의 '지금 쓰는 칸'은 이것을 보인다.
    var ownedTier: PlanTier { isGrandfathered ? .pro : ProEntitlement.tier(owning: ownedProductIDs) }

    /// 평생으로 이미 가졌는가 (산 것이든 페이월 전부터 쓰던 분이든).
    var hasLifetimePro: Bool { isGrandfathered || ownsLifetime(.pro) }

    /// 이 칸을 아직 살 것이 있는가. 평생으로 이미 가졌으면 없다. 구독으로 쓰는 칸은 평생으로 바꿀 수 있다.
    func canBuy(_ tier: PlanTier) -> Bool {
        if hasLifetimePro { return false }
        if tier == .plus && ownsLifetime(.plus) { return false }
        // 상품을 아직 못 본 기기는 모두 열려 있지만(`ProEntitlement.tier`), 살 수 있는 것은 산 것으로 정한다.
        return ownedTier <= tier
    }

    // MARK: - 상태 맞추기

    /// 영수증을 다시 읽어 칸을 정한다. 앱이 켜질 때와 돌아올 때마다 부른다.
    func refresh() async {
        await store.refreshEntitlements()
        await store.loadProducts()
        entitlementsChecked = true
        subscription = await Self.yearlySubscription()
        pull()
    }

    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    /// 구독 졸업을 제안할 때인가. 연 구독 6개월째와 갱신 7일 전에 한 번씩.
    var graduationIsDue: Bool {
        guard let subscription, product(ProEntitlement.graduateID) != nil, !hasLifetimePro else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    func markGraduationOffered() { LeeoGraduation.markOffered() }

    // MARK: - 사기 / 되찾기

    /// ⚠️ `action` 은 페이월의 `@Environment(\.purchase)` 다. 아이패드에서 결제 시트가 엉뚱한 창에 뜨지 않게.
    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        entitlementsChecked = true
        subscription = await Self.yearlySubscription()
        pull()
    }

    func restore() async {
        await store.restore()
        entitlementsChecked = true
        subscription = await Self.yearlySubscription()
        pull()
        if ownedTier == .free, failureMessage == nil {
            failureMessage = String(localized: "이 Apple 계정에서 구매한 기록을 찾지 못했어요.")
        }
    }

    // MARK: -

    private func pull() {
        if store.products.contains(where: { ProEntitlement.tierByProduct[$0.id] != nil }) {
            ProEntitlement.noteSold()
        }
        if entitlementsChecked {
            ProEntitlement.setTier(store.isGrandfathered ? .pro : ProEntitlement.tier(owning: store.purchasedProductIDs))
        }
        tier = ProEntitlement.tier
        isGrandfathered = store.isGrandfathered
        products = store.products
        ownedProductIDs = store.purchasedProductIDs
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
    }

    /// 연 구독 중이면 그 구독. 졸업가는 연 구독에만 준다(주 · 월 구독에 주면 한 주 값으로 평생이 싸진다).
    private static func yearlySubscription() async -> LeeoGraduation.Subscription? {
        await LeeoGraduation.currentSubscription(among: ProEntitlement.yearlyIDs)
    }

    /// 페이월 전부터 쓰던 분은 Pro 평생이다. 지금은 모두 iCloud 로 여러 기기에 기록을 두고 있어, 동기화를 끊으면 안 된다.
    ///  ① 이 기기에 페이월 전부터 기록 저장소가 있었다 (`ProEntitlement.noteStoreBeforePaywall`).
    ///  ② 이 Apple 계정이 페이월 없던 빌드(`lastFreeBuild` 이하)로 앱을 처음 받았다 — 새 기기에서도 이어진다.
    /// ⚠️ 샌드박스 · TestFlight 의 `originalAppVersion` 은 늘 "1.0" 이라 출시 환경에서만 ②를 본다.
    private static func isGrandfathered() async -> Bool {
        if ProEntitlement.hadStoreBeforePaywall { return true }
        guard let result = try? await AppTransaction.shared,
              case .verified(let app) = result,
              app.environment == .production,
              let build = Int(app.originalAppVersion) else { return false }
        return build <= ProEntitlement.lastFreeBuild
    }
}
