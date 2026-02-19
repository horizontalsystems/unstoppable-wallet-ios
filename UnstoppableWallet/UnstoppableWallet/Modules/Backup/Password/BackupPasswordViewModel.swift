import Combine
import Foundation

class BackupPasswordViewModel: ObservableObject {
    @Published var password: String = "" {
        didSet { clearCautions() }
    }

    @Published var confirm: String = "" {
        didSet { clearCautions() }
    }

    @Published var passwordCautionState: CautionState = .none
    @Published var confirmCautionState: CautionState = .none

    var isValid: Bool {
        passwordCautionState == .none && !password.isEmpty &&
            confirmCautionState == .none && !confirm.isEmpty
    }

    init() {
        let defaultPassphrase = AppConfig.defaultPassphrase
        if !defaultPassphrase.isEmpty {
            password = defaultPassphrase
            confirm = defaultPassphrase
        }
    }

    func validate() {
        validatePassword()
        validateConfirm()
    }

    private func validatePassword() {
        do {
            try BackupCrypto.validate(passphrase: password)
            passwordCautionState = .none
        } catch {
            passwordCautionState = .caution(Caution(text: error.localizedDescription, type: .error))
        }
    }

    private func validateConfirm() {
        do {
            try BackupCrypto.validate(passphrase: confirm)

            if password != confirm {
                confirmCautionState = .caution(Caution(
                    text: "backup.cloud.password.confirm.error.doesnt_match".localized,
                    type: .error
                ))
            } else {
                confirmCautionState = .none
            }
        } catch {
            confirmCautionState = .caution(Caution(text: error.localizedDescription, type: .error))
        }
    }

    private func clearCautions() {
        if passwordCautionState != .none {
            passwordCautionState = .none
        }
        if confirmCautionState != .none {
            confirmCautionState = .none
        }
    }
}
