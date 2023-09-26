import Combine

class CreatePasscodeViewModel: SetPasscodeViewModel {
    private let reason: CreatePasscodeModule.CreatePasscodeReason
    private let onCreate: () -> Void
    private let _onCancel: () -> Void

    init(passcodeManager: PasscodeManager, reason: CreatePasscodeModule.CreatePasscodeReason, onCreate: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.reason = reason
        self.onCreate = onCreate
        _onCancel = onCancel

        super.init(passcodeManager: passcodeManager)
    }

    override var title: String {
        "create_passcode.title".localized
    }

    override var passcodeDescription: String {
        reason.description
    }

    override var confirmDescription: String {
        "create_passcode.confirm_passcode".localized
    }

    override func onEnter(passcode: String) {
        do {
            try passcodeManager.set(passcode: passcode)
            finishSubject.send()
            onCreate()
        } catch {
            print("Create Passcode Error: \(error)")
        }
    }

    override func onCancel() {
        _onCancel()
    }
}
