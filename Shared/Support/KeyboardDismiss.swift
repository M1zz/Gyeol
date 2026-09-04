import SwiftUI

/// Dismisses the keyboard when the user taps anywhere that isn't a text input.
///
/// Each input reports its own frame, so a tap *inside* the field being edited still just
/// moves the caret, and a tap on a different field hands focus over instead of closing
/// the keyboard — which a blanket "any tap clears focus" gesture gets wrong.
private struct InputFrameKey: PreferenceKey {
    static let defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    /// Marks a text input so `dismissesKeyboardOnOutsideTap` leaves its taps alone.
    func keyboardInput(in space: String) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(key: InputFrameKey.self, value: [geometry.frame(in: .named(space))])
            }
        )
    }

    /// A no-op off iOS — a Mac has no software keyboard to get out of the way.
    @ViewBuilder
    func dismissesKeyboardOnOutsideTap(
        space: String,
        isEditing: Bool,
        dismiss: @escaping () -> Void
    ) -> some View {
        #if os(iOS)
        modifier(OutsideTapDismiss(space: space, isEditing: isEditing, dismiss: dismiss))
        #else
        self
        #endif
    }
}

#if os(iOS)
private struct OutsideTapDismiss: ViewModifier {
    let space: String
    let isEditing: Bool
    let dismiss: () -> Void

    @State private var inputFrames: [CGRect] = []

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: space)
            .onPreferenceChange(InputFrameKey.self) { inputFrames = $0 }
            .simultaneousGesture(
                // minimumDistance 0 so a plain tap is delivered; the translation check
                // keeps a scroll from being mistaken for one.
                DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
                    .onEnded { value in
                        guard isEditing,
                              abs(value.translation.width) < 10,
                              abs(value.translation.height) < 10,
                              !inputFrames.contains(where: { $0.contains(value.location) })
                        else { return }
                        dismiss()
                    }
            )
    }
}
#endif
