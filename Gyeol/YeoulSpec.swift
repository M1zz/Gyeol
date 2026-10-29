//
//  YeoulSpec.swift
//  Gyeol
//
//  LeeoKit 계약(LeeoAppSpec) 준수 — 이 앱의 공통 기능 설정값 단일 소스.
//  피드백·리뷰·진단 구현은 전부 LeeoKit 에 있고, 앱은 이 설정만 제공한다.
//
//  ⚠️ iOS 타깃(Gyeol)에만 들어간다. Shared/ 에 두면 맥 타깃(YeoulMac)도 LeeoKit 이 필요해진다.
//

import Foundation
import LeeoKit

enum YeoulSpec: LeeoAppSpec {
    static let appName = "여울"
    static let developerEmail = "leeo@kakao.com"

    /// 공용 피드백 허브(FeedbackHub)로 수집 — appIdentifier(번들 ID)로 앱을 구분한다.
    /// 컨테이너 권한은 Config/iOS.entitlements 에 있다 (기록 동기화용 iCloud.com.leeo.yeoul 과 나란히).
    /// 맥 타깃(YeoulMac)은 LeeoKit 을 안 쓰므로 아무것도 보내지 않는다.
    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.leeo.yeoul"
    )

    /// 익명 사용 통계 — 설치 수·실행 일수·버전 분포를 FeedbackHub 로 보낸다.
    /// 기본값(LeeoNoopAnalytics)이면 부트스트랩이 아무것도 안 보낸다. 무엇을 보내는지는 docs/privacy.html.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: YeoulSpec.self)

    /// 개인정보·지원 페이지 (LeeoKit 3.x 부터 필수) — docs/ 의 GitHub Pages.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/Gyeol/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/Gyeol/support.html")!,
        marketingURL: URL(string: "https://m1zz.github.io/Gyeol/")!
    )

    /// App Store ID — 설정의 "리뷰 남기기"가 작성 페이지로 바로 간다.
    static let appStoreID: String? = "6808471728"

    /// 수익모델 (LeeoKit 3.x 부터 필수) — 기능을 여는 결제가 없는 무료 앱.
    static let monetization = LeeoMonetization.free

    /// 개발자 응원(팁). 소모성 세 가지, 작은 것부터. 기능을 열지 않는다 — 무료 앱이라 혼자 돈다(`startStandalone`).
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.leeo.yeoul.tip.small", "com.leeo.yeoul.tip.medium", "com.leeo.yeoul.tip.large",
    ]))
}
