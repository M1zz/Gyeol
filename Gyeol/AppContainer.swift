import SwiftData
import LeeoKit

/// The one store the iOS app opens. The scene and the Shortcuts actions share it, so a
/// milestone added from Siri shows up in an open window straight away and the CloudKit
/// mirror is never set up twice in one process.
@MainActor
enum AppContainer {
    static let shared: ModelContainer = Store.makeContainer(
        allowsCloudSync: LeeoRemoteFlags.isEnabled(YeoulFlag.cloudSyncEnabled)
    )
}
