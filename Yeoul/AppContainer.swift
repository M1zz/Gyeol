import SwiftData
import LeeoKit

/// The one store the iOS app opens. The scene and the Shortcuts actions share it, so a
/// milestone added from Siri shows up in an open window straight away and the CloudKit
/// mirror is never set up twice in one process.
@MainActor
enum AppContainer {
    static let shared: ModelContainer = {
        // 저장소 파일을 만들기 전에, 페이월 전부터 쓰던 기기인지 한 번 적어 둔다 (→ ProEntitlement).
        ProEntitlement.noteStoreBeforePaywall()
        // iCloud 동기화는 Pro 다. 원격 킬스위치가 꺼도 멈춘다. 바뀐 값은 다음 실행부터 따른다.
        return Store.makeContainer(
            allowsCloudSync: LeeoRemoteFlags.isEnabled(YeoulFlag.cloudSyncEnabled) && ProEntitlement.syncsWithICloud
        )
    }()
}
