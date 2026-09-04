import SwiftUI
import SwiftData

@main
struct GyeolApp: App {
    var body: some Scene {
        WindowGroup {
            TimelineListView()
        }
        .modelContainer(for: [Timeline.self, TimelineEvent.self])
    }
}
