import SwiftUI
import SwiftData
import TipKit

@main
struct YeoulMacApp: App {
    init() {
        // Tips on the timeline (open a card, tap a tag) — Shared/Support/FeatureTips.swift.
        try? Tips.configure()
    }

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
