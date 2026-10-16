import SwiftUI
import SwiftData
import TipKit
import LeeoKit

@main
struct GyeolApp: App {
    init() {
        // LeeoKit 계약을 켜는 한 줄 (→ YeoulSpec.swift). 실행 횟수 기록 · 익명 사용 통계 ·
        // 크래시 진단 · 원격 킬스위치(YeoulFlags.swift) 갱신 · DEBUG 프리플라이트.
        // 통계·진단·플래그는 FeedbackHub(CloudKit)를 쓴다 —
        // 그 iCloud 컨테이너 권한은 Config/iOS.entitlements 에 있다 (없으면 CKContainer 에서 죽는다).
        LeeoKit.bootstrap(YeoulSpec.self, flags: YeoulFlag.self)

        // 사건을 새로 남긴 순간이 이 앱에서 "잘 쓰고 있다"는 신호다.
        // 만족도 질문(.leeoSatisfactionCheck)은 이 횟수를 보고 뜬다.
        AppActivity.eventSaved = { isNew in
            if isNew { _ = LeeoEngagement.shared.registerSignificantEvent() }
        }

        // 타임라인 화면의 사용 팁 (Shared/Support/FeatureTips.swift)
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            TimelineListView()
                .leeoSatisfactionCheck(YeoulSpec.self)
        }
        .modelContainer(AppContainer.shared)
    }
}
