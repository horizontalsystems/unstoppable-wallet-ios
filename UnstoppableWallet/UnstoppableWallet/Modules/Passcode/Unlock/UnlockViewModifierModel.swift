import Combine

class UnlockViewModifierModel: ObservableObject {
    private let passcodeManager = Core.shared.passcodeManager

    @Published var unlockPresented = false

    var onUnlock: (() -> Void)?

    func handle(onUnlock: @escaping () -> Void) {
        if passcodeManager.isPasscodeSet {
            self.onUnlock = onUnlock
            unlockPresented = true
        } else {
            onUnlock()
        }
    }
}
