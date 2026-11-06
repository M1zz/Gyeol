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

    /// Whether the container this run opened mirrors to iCloud. Settings compares it with
    /// what the user now wants, to say the change lands on the next launch.
    private(set) static var isMirroring = false

    /// - Parameter allowsCloudSync: false opens the same on-device store without iCloud
    ///   mirroring. The iOS app passes its remote kill switch and the plan (sync is Pro)
    ///   here, so sync can also be turned off without a review if it ever starts damaging
    ///   records; nothing local is lost.
    static func makeContainer(allowsCloudSync: Bool = true) -> ModelContainer {
        if allowsCloudSync, syncsWithCloud, let cloud = try? ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudContainer))
        ) {
            isMirroring = true
            return cloud
        }
        isMirroring = false

        // A device with no iCloud account should still be able to keep local records.
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            )
        } catch {
            return StoreFallback.memoryContainer(schema: schema, after: error)
        }
    }
}
