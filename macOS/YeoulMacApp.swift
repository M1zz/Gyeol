import SwiftUI
import SwiftData

@main
struct YeoulMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacRootView()
        }
        .modelContainer(Store.makeContainer())
        .defaultSize(width: 1180, height: 820)
        .commands {
            SidebarCommands()
        }
    }
}
