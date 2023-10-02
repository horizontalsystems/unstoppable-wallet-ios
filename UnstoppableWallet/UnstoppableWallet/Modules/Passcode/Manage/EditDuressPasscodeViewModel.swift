import Combine

class EditDuressPasscodeViewModel: SetPasscodeViewModel {
    override var title: String {
        "edit_duress_passcode.title".localized
    }

    override var passcodeDescription: String {
        "edit_duress_passcode.enter_new_passcode".localized
    }

    override var confirmDescription: String {
        "edit_duress_passcode.confirm_new_passcode".localized
    }

    override func isCurrent(passcode: String) -> Bool {
        passcodeManager.isValid(duressPasscode: passcode)
    }

    override func onEnter(passcode: String) {
        do {
            try passcodeManager.set(duressPasscode: passcode)
            finishSubject.send()
        } catch {
            print("Edit Duress Passcode Error: \(error)")
        }
    }
}
