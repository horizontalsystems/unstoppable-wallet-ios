import Combine
import Foundation

class BackupPasswordViewModel: ObservableObject {
    private let storage: IBackupPasswordStorage = BackupPasswordStorageFactory.create(type: .webCredentials)
    private let destination: BackupModule.Destination
    private var keychainAccount: String = ""

    @Published var password: String = "" {
        didSet { clearCautions() }
    }

    @Published var confirm: String = "" {
        didSet { clearCautions() }
    }

    @Published var passwordCautionState: CautionState = .none
    @Published var confirmCautionState: CautionState = .none

    // True only when user explicitly chose generated password with .cloud destination
    private(set) var shouldSaveToKeychain = false

    var isValid: Bool {
        passwordCautionState == .none && !password.isEmpty &&
            confirmCautionState == .none && !confirm.isEmpty
    }

    init(destination: BackupModule.Destination) {
        self.destination = destination

        let defaultPassphrase = AppConfig.defaultPassphrase
        if !defaultPassphrase.isEmpty {
            password = defaultPassphrase
            confirm = defaultPassphrase
        }
    }

    func prepareKeychain(name: String) {
        keychainAccount = name
    }

    func useGeneratedPassword() throws {
        let generated = try BackupPasswordGenerator.generate()
        password = generated
        confirm = generated
        // Save to Keychain only for cloud backups
        shouldSaveToKeychain = destination == .cloud
    }

    func saveIfNeeded() async throws {
        validate()
        guard isValid else {
            throw ValidationError.invalid
        }

        guard shouldSaveToKeychain else { return }

        guard !keychainAccount.isEmpty else {
            throw ValidationError.emptyKeychainAccount
        }

        try await storage.save(password: password, account: keychainAccount)
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

extension BackupPasswordViewModel {
    enum ValidationError: Error {
        case invalid
        case emptyKeychainAccount
    }
}
