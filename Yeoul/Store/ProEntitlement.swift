//
//  ProEntitlement.swift
//  Yeoul
//
//  상품 ID 와 "지금 어느 칸인가"의 한 줄. 무엇이 어느 칸인지는 `Shared/Support/Plan.swift` 에 있다.
//
//  StoreKit 은 여기 없다. 영수증 확인은 `PurchaseManager` 가 하고 그 결과를 여기 한 줄로 적는다.
//  앱을 켤 때 저장소를 고르는 `AppContainer` 와 Siri 의 `AddEventIntent` 가 StoreKit 을 기다리지 않고 읽게.
//
//  ⚠️ 팁은 권한이 아니다. 팁 상품을 `tierByProduct` 에 넣지 않는다.
//  ⚠️ 언제나 평생 패스는 팔지 않는다(포트폴리오 전체에서 판매를 멈췄다).
//

import Foundation

enum ProEntitlement {

    // MARK: - 상품 ID
    //
    // ⚠️ App Store Connect · `Config/Yeoul.storekit` 과 글자 하나까지 같아야 한다.
    //    주 · 월 · 연 구독 여섯은 **한 구독 그룹**에 넣는다(Pro 가 위 단계). 그래야 서로 갈아탄다.

    private static let prefix = "com.leeo.yeoul"

    static let plusWeeklyID   = prefix + ".plus.weekly"
    static let plusMonthlyID  = prefix + ".plus.monthly"
    static let plusYearlyID   = prefix + ".plus.yearly"
    /// Plus 평생.
    static let plusLifetimeID = prefix + ".plus"
    static let proWeeklyID    = prefix + ".pro.weekly"
    static let proMonthlyID   = prefix + ".pro.monthly"
    static let proYearlyID    = prefix + ".pro.yearly"
    /// Pro 평생.
    static let proLifetimeID  = prefix + ".pro"
    /// Plus 평생을 산 사람이 Pro 평생으로 올리는 값.
    static let upgradeID      = prefix + ".pro.upgrade"
    /// 구독 중인 사람의 졸업가 Pro 평생 (→ LeeoGraduation).
    static let graduateID     = prefix + ".pro.graduate"

    /// 개발자 응원 팁 (소모성 셋, 작은 것부터). 아무것도 열지 않는다.
    static let tipProductIDs = [prefix + ".tip.small", prefix + ".tip.medium", prefix + ".tip.large"]

    /// 페이월이 불러올 상품. 스토어에 아직 없는 것은 불러와지지 않고, 그 단추는 서지 않는다.
    static let productIDs = [plusYearlyID, plusLifetimeID, proYearlyID, proLifetimeID, upgradeID, graduateID,
                             plusWeeklyID, plusMonthlyID, proWeeklyID, proMonthlyID]

    /// 상품마다 여는 칸. 구독은 같은 칸의 평생과 같은 권한, 올리기 · 졸업은 Pro 평생이다.
    static let tierByProduct: [String: PlanTier] = [
        plusWeeklyID: .plus, plusMonthlyID: .plus, plusYearlyID: .plus, plusLifetimeID: .plus,
        proWeeklyID: .pro, proMonthlyID: .pro, proYearlyID: .pro, proLifetimeID: .pro,
        upgradeID: .pro, graduateID: .pro,
    ]

    static var entitlementIDs: Set<String> { Set(tierByProduct.keys) }

    /// 평생 상품 (끝나지 않는 것).
    static let lifetimeIDs: Set<String> = [plusLifetimeID, proLifetimeID, upgradeID, graduateID]

    /// 연 구독. 구독 졸업을 제안할 대상이다. 주 · 월 구독에 졸업가를 주면 한 주 값으로 평생이 싸진다.
    static let yearlyIDs: Set<String> = [plusYearlyID, proYearlyID]

    /// 자동 갱신 구독 전부.
    static let subscriptionIDs: Set<String> = [plusWeeklyID, plusMonthlyID, plusYearlyID,
                                               proWeeklyID, proMonthlyID, proYearlyID]

    /// 가진 상품이 여는 칸. 가장 높은 것을 쓴다.
    static func tier(owning productIDs: Set<String>) -> PlanTier {
        productIDs.compactMap { tierByProduct[$0] }.max() ?? .free
    }

    /// 이 칸의 평생을 이미 가졌는가.
    static func ownsLifetime(_ tier: PlanTier, in productIDs: Set<String>) -> Bool {
        productIDs.contains { lifetimeIDs.contains($0) && tierByProduct[$0] == tier }
    }

    // MARK: - 지금 쓰는 칸 (영수증의 거울)

    private static let tierKey = "plan.tier"
    private static let everSoldKey = "plan.everSold"
    private static var defaults: UserDefaults { .standard }

    /// 지금 쓰는 칸 — 화면 · Siri · 저장소가 모두 이것을 본다.
    ///
    /// **스토어에서 유료 칸 상품을 한 번도 불러오지 못한 기기는 막지 않는다.** 상품을 만들기 전에 나간
    /// 빌드에서 살 수 없는 자물쇠만 서지 않게. 한 번이라도 불러왔으면(`everSold`) 그 뒤로는
    /// 오프라인이어도 영수증대로 막는다.
    static var tier: PlanTier {
        #if DEBUG
        if ScreenshotDemo.isActive { return .pro }
        #endif
        #if os(iOS)
        guard everSold else { return .pro }
        #endif
        // 맥 앱은 요금제와 함께 처음 나왔다. 상품을 못 본 기기라고 열어 둘 까닭이 없다.
        return cachedTier ?? .free
    }

    /// 적혀 있는 답. **nil 은 '무료'가 아니라 '아직 애플에게 안 물어봤다'** 이다.
    static var cachedTier: PlanTier? {
        (defaults.object(forKey: tierKey) as? Int).flatMap(PlanTier.init(rawValue:))
    }

    /// 이 기기가 스토어에서 유료 칸 상품을 한 번이라도 본 적이 있는가.
    static var everSold: Bool { defaults.bool(forKey: everSoldKey) }

    /// `PurchaseManager` 만 부른다.
    static func setTier(_ value: PlanTier) {
        guard cachedTier != value else { return }
        defaults.set(value.rawValue, forKey: tierKey)
    }

    /// `PurchaseManager` 만 부른다. 내려가지 않는다.
    static func noteSold() {
        guard !everSold else { return }
        defaults.set(true, forKey: everSoldKey)
    }

    // MARK: - iCloud 동기화

    private static let syncWantedKey = "plan.sync.wanted"

    /// 사용자가 설정에서 동기화를 켜 두었는가. 처음엔 켜져 있다(페이월 전부터 쓰던 분은 모두 동기화 중이었다).
    static var syncWanted: Bool {
        get { defaults.object(forKey: syncWantedKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: syncWantedKey) }
    }

    /// 이번 실행에 iCloud 로 맞출 것인가. 저장소를 열기 전에 한 번 읽는다.
    ///
    /// 아직 애플에게 묻기 전(nil)이면 켠다. 페이월 전부터 쓰던 분은 곧 Pro 로 확인된다(`isGrandfathered`).
    /// 확인 전 한 번 꺼 버리면 그사이 적은 것이 다른 기기에 늦게 간다.
    /// ⚠️ 끄더라도 기기 안 기록은 그대로다. iCloud 쪽 사본도 지우지 않는다.
    static var syncsWithICloud: Bool {
        guard syncWanted else { return false }
        if cachedTier == nil {
            // 맥 앱은 요금제와 함께 처음 나왔다. 확인 전에는 켜지 않고, Pro 로 확인되면 다음 실행부터 켠다.
            #if os(macOS)
            return false
            #else
            // (상품을 못 본 기기는 아래 `tier` 가 Pro 라 어차피 켠다.)
            return true
            #endif
        }
        return tier >= PlanFeature.iCloudSync.tier
    }

    // MARK: - 페이월 전부터 쓰던 분

    /// 페이월이 없던 마지막 빌드(1.0.3 빌드 6). 이 빌드 이하로 처음 받은 Apple 계정은 Pro 평생이다.
    static let lastFreeBuild = 6

    private static let legacyCheckedKey = "plan.legacy.checked"
    private static let legacyDeviceKey = "plan.legacy.device"

    /// 이 기기에 페이월 전부터 쓰던 기록 저장소가 있었는가.
    static var hadStoreBeforePaywall: Bool { defaults.bool(forKey: legacyDeviceKey) }

    /// 페이월이 생긴 버전을 **처음 켤 때 한 번만**, 저장소를 열기 전에 적는다.
    /// 그때 이미 기기에 저장소 파일이 있었으면 쓰던 분이다. 그 뒤에 생긴 저장소는 세지 않는다.
    static func noteStoreBeforePaywall() {
        guard !defaults.bool(forKey: legacyCheckedKey) else { return }
        defaults.set(true, forKey: legacyCheckedKey)
        let store = URL.applicationSupportDirectory.appending(path: "default.store")
        if FileManager.default.fileExists(atPath: store.path(percentEncoded: false)) {
            defaults.set(true, forKey: legacyDeviceKey)
        }
    }
}
