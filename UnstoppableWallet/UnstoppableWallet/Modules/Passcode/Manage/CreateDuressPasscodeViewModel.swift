import Combine

class CreateDuressPasscodeViewModel: SetPasscodeViewModel {
    override var title: String {
        "create_duress_passcode.title".localized
    }

    override var passcodeDescription: String {
        "create_duress_passcode.description".localized
    }

    override var confirmDescription: String {
        "create_duress_passcode.confirm_passcode".localized
    }

    override func onEnter(passcode: String) {
        do {
            try passcodeManager.set(duressPasscode: passcode)
            finishSubject.send()
        } catch {
            print("Create Duress Passcode Error: \(error)")
        }
    }
}
