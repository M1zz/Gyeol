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
    /// ⚠️ 아직 이 앱의 entitlements(Config/iOS.entitlements)에 iCloud.com.Ysoup.FeedbackHub 컨테이너가 **없다.**
    ///    (지금은 기록 동기화용 iCloud.com.leeo.yeoul 하나뿐)
    ///    그래서 부트스트랩에서 크래시 진단(CloudKit 전송)을 꺼 두었다 (→ GyeolApp).
    ///    피드백 화면·진단을 켜기 전에 이 컨테이너부터 넣고, 개인정보처리방침(docs/privacy.html)도 같이 고칠 것.
    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.leeo.yeoul"
    )

    /// 개인정보·지원 페이지 (LeeoKit 3.x 부터 필수) — docs/ 의 GitHub Pages.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/Gyeol/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/Gyeol/support.html")!,
        marketingURL: URL(string: "https://m1zz.github.io/Gyeol/")!
    )

    /// 수익모델 (LeeoKit 3.x 부터 필수) — StoreKit 코드가 없는 무료 앱.
    static let monetization = LeeoMonetization.free
}
