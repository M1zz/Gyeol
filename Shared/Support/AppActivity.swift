import Foundation

/// The moments that tell the app a person got something out of it.
///
/// Shared views fire these; each app decides what to do with them. The iOS app counts a
/// saved milestone toward its "are you enjoying 여울?" check (LeeoKit). The Mac app links no
/// LeeoKit, so it leaves the hook empty and nothing happens there.
@MainActor
enum AppActivity {
    /// Called after a milestone is written to the store. `isNew` is false for edits.
    static var eventSaved: (_ isNew: Bool) -> Void = { _ in }
}
