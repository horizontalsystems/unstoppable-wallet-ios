import Combine
import Foundation

class ModuleUnlockViewModel: BaseUnlockViewModel {
    private let onUnlock: () -> Void

    init(biometryAllowed: Bool, onUnlock: @escaping () -> Void) {
        self.onUnlock = onUnlock

        super.init(biometryAllowed: biometryAllowed)
    }

    override func onEnterValid(passcode _: String) {
        onUnlock()
        finishSubject.send()
    }

    override func onBiometryUnlock() {
        onUnlock()
        finishSubject.send()
    }
}
