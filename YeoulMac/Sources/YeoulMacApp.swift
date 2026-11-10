import SwiftUI
import SwiftData
import TipKit
import LeeoKit

@main
struct YeoulMacApp: App {
    init() {
        // LeeoKit 계약을 켜는 한 줄 (→ Yeoul/YeoulSpec.swift). iOS 앱과 같은 계약 · 같은 상품을 쓴다.
        // 통계 · 진단 · 플래그는 FeedbackHub(CloudKit)를 쓴다 — 그 컨테이너 권한은 Config/macOS.entitlements 에 있다.
        LeeoKit.bootstrap(YeoulSpec.self, flags: YeoulFlag.self)

        #if DEBUG
        // 스토어 스크린샷: 언어별 예시 기록을 넣고, 팁은 감춘다 (Shared/Support/ScreenshotDemo.swift)
        if ScreenshotDemo.isActive {
            ScreenshotDemo.seedIfRequested(into: Self.container)
            Tips.hideAllTipsForTesting()
        }
        #endif

        // Tips on the timeline (open a card, tap a tag) — Shared/Support/FeatureTips.swift.
        try? Tips.configure()
    }

    /// 이 앱이 여는 저장소. iCloud 동기화는 Pro 이고, iOS 앱과 같은 규칙으로 고른다 (→ Yeoul/AppContainer.swift).
    ///
    /// ⚠️ 스크린샷 모드는 **메모리 저장소만** 쓴다. 예시 기록을 넣기 전에 저장소를 비우는데,
    /// 맥에는 시뮬레이터가 없어 진짜 저장소를 열면 사용자의 기록이 지워지고 그 삭제가 iCloud 로 퍼진다.
    private static let container: ModelContainer = {
        #if DEBUG
        if ScreenshotDemo.isActive {
            return try! ModelContainer(
                for: Store.schema,
                configurations: ModelConfiguration(schema: Store.schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        }
        #endif
        return AppContainer.shared
    }()

    var body: some Scene {
        WindowGroup {
            MacRootView()
                .storeFallbackNotice()
                // 지금 칸 · 페이월 · 영수증 다시 읽기 · 구독 졸업 (→ Yeoul/Store/PlanRoot.swift)
                .planRoot()
        }
        .modelContainer(Self.container)
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
