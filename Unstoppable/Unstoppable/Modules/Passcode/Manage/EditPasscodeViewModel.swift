import Combine

class EditPasscodeViewModel: SetPasscodeViewModel {
    override var title: String {
        "edit_passcode.title".localized
    }

    override var passcodeDescription: String {
        "edit_passcode.enter_new_passcode".localized
    }

    override var confirmDescription: String {
        "edit_passcode.confirm_new_passcode".localized
    }

    override func isCurrent(passcode: String) -> Bool {
        passcodeManager.isValid(passcode: passcode)
    }

    override func onEnter(passcode: String) {
        do {
            try passcodeManager.set(passcode: passcode)
            finishSubject.send()
        } catch {
            print("Edit Passcode Error: \(error)")
        }
    }
}
