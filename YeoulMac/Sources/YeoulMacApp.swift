import SwiftUI
import SwiftData
import TipKit
import LeeoKit

@main
struct YeoulMacApp: App {
    init() {
        // LeeoKit 계약을 켜는 한 줄 (→ Gyeol/YeoulSpec.swift). iOS 앱과 같은 계약 · 같은 상품을 쓴다.
        // 통계 · 진단 · 플래그는 FeedbackHub(CloudKit)를 쓴다 — 그 컨테이너 권한은 Config/macOS.entitlements 에 있다.
        LeeoKit.bootstrap(YeoulSpec.self, flags: YeoulFlag.self)

        // Tips on the timeline (open a card, tap a tag) — Shared/Support/FeatureTips.swift.
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            MacRootView()
                .storeFallbackNotice()
                // 지금 칸 · 페이월 · 영수증 다시 읽기 · 구독 졸업 (→ Gyeol/Store/PlanRoot.swift)
                .planRoot()
        }
        // iCloud 동기화는 Pro 다. 저장소는 iOS 앱과 같은 규칙으로 고른다 (→ Gyeol/AppContainer.swift).
        .modelContainer(AppContainer.shared)
        .defaultSize(width: 1180, height: 820)
        .commands {
            SidebarCommands()
        }

        // 여울 ▸ 설정… (⌘,) — 요금제 · 구매 복원 · iCloud 동기화 · 지원
        Settings {
            MacSettingsView()
        }
    }
}
