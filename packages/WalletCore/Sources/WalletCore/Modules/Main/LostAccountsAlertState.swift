/// Keeps a successful removal's refreshed records alive until the sheet has closed.
final class LostAccountsAlertState {
    private(set) var isPresented = false
    private var removalSucceeded = false

    /// Starts a new sheet with acknowledgement as its default dismissal behavior.
    func beginPresentation() {
        isPresented = true
        removalSucceeded = false
    }

    /// Changes dismissal behavior only after persistent removal succeeds.
    func remove(using action: () throws -> Void) rethrows {
        try action()
        removalSucceeded = true
    }

    /// Acknowledgement clears the warning; removal preserves the newly published records.
    /// Resume alert handling after releasing the presentation guard in either case.
    func dismiss(clearRecords: () -> Void, showNextAlert: () -> Void) {
        if !removalSucceeded {
            clearRecords()
        }
        isPresented = false
        removalSucceeded = false
        showNextAlert()
    }
}
