import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage
#endif

extension Image {
    init(platform image: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: image)
        #else
        self.init(nsImage: image)
        #endif
    }
}

extension PlatformImage {
    convenience init?(platformData data: Data) {
        self.init(data: data)
    }
}

/// The handful of semantic colours the cards rely on. UIKit and AppKit spell them
/// differently, and a couple have no exact counterpart, so they are named once here.
enum Palette {
    static var cardSurface: Color {
        #if canImport(UIKit)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var groupedBackground: Color {
        #if canImport(UIKit)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var pageBackground: Color {
        #if canImport(UIKit)
        Color(.systemBackground)
        #else
        Color(nsColor: .textBackgroundColor)
        #endif
    }

    static var separator: Color {
        #if canImport(UIKit)
        Color(.separator)
        #else
        Color(nsColor: .separatorColor)
        #endif
    }

    static var faintLabel: Color {
        #if canImport(UIKit)
        Color(.tertiaryLabel)
        #else
        Color(nsColor: .tertiaryLabelColor)
        #endif
    }
}

/// A few SwiftUI modifiers only exist on iOS. Wrapping them once keeps the shared views
/// free of `#if` noise.
extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func dismissKeyboardOnScroll() -> some View {
        #if os(iOS)
        scrollDismissesKeyboard(.interactively)
        #else
        self
        #endif
    }

    /// Tag entry: no autocorrect, and no automatic capitalisation where that exists.
    @ViewBuilder
    func plainTextEntry() -> some View {
        #if os(iOS)
        autocorrectionDisabled().textInputAutocapitalization(.never)
        #else
        autocorrectionDisabled()
        #endif
    }
}

/// Opens the system settings page where photo access is granted.
func openPhotoPrivacySettings() {
    #if os(iOS)
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
    #else
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
        NSWorkspace.shared.open(url)
    }
    #endif
}

extension View {
    /// A macOS sheet takes its content's *ideal* size. A Form full of sections wants to be
    /// taller than the screen, and the overflow is clipped rather than scrolled — the
    /// bottom sections simply become unreachable. Giving the sheet a real size makes the
    /// Form scroll inside it. On iOS the sheet already manages its own height.
    @ViewBuilder
    func editorSheetFrame(idealHeight: CGFloat = 640) -> some View {
        #if os(macOS)
        frame(minWidth: 560, idealWidth: 640, minHeight: 380, idealHeight: idealHeight)
        #else
        self
        #endif
    }

    /// macOS lays a plain Form out as a label/content grid, which squeezes wide rows like
    /// the card preview. Grouped matches how these forms were designed.
    @ViewBuilder
    func groupedForm() -> some View {
        #if os(macOS)
        formStyle(.grouped)
        #else
        self
        #endif
    }
}
