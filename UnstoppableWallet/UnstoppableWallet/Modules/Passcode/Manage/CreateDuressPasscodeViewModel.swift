import Combine
import ComponentKit

class CreateDuressPasscodeViewModel: SetPasscodeViewModel {
    private let accountIds: [String]
    private let accountManager: AccountManager

    init(accountIds: [String], accountManager: AccountManager, passcodeManager: PasscodeManager) {
        self.accountIds = accountIds
        self.accountManager = accountManager

        super.init(passcodeManager: passcodeManager)
    }

    override var title: String {
        "enable_duress_mode.passcode.title".localized
    }

    override var passcodeDescription: String {
        "enable_duress_mode.passcode.description".localized
    }

    override var confirmDescription: String {
        "enable_duress_mode.passcode.confirm".localized
    }

    override func onEnter(passcode: String) {
        do {
            try passcodeManager.set(duressPasscode: passcode)

            if !accountIds.isEmpty {
                accountManager.setDuress(accountIds: accountIds)
            }

            finishSubject.send()
            HudHelper.instance.show(banner: .created)
        } catch {
            print("Create Duress Passcode Error: \(error)")
        }
    }
}
