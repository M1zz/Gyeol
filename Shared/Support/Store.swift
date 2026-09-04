import Foundation
import SwiftData

/// Both apps open the same private CloudKit database, so a milestone written on the
/// phone shows up on the Mac. The container is named explicitly rather than left to
/// default, because the two apps have to agree on it.
enum Store {
    static let cloudContainer = "iCloud.com.leeo.yeoul"

    static let schema = Schema([Timeline.self, TimelineEvent.self])

    /// CloudKit traps inside its own setup if the running binary isn't entitled to the
    /// container — which is the case for an unsigned local build — so `-localOnly` gives
    /// a way to run the UI without provisioning. It is never passed by a real launch.
    static var syncsWithCloud: Bool {
        !ProcessInfo.processInfo.arguments.contains("-localOnly")
    }

    static func makeContainer() -> ModelContainer {
        if syncsWithCloud, let cloud = try? ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudContainer))
        ) {
            return cloud
        }

        // A device with no iCloud account should still be able to keep local records.
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            )
        } catch {
            fatalError("기록 저장소를 열지 못했습니다: \(error)")
        }
    }
}
