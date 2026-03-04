import Combine
import Foundation

class BackupPasswordViewModel: ObservableObject {
    private let storage: IBackupPasswordStorage = BackupPasswordStorageFactory.create(type: .webCredentials)
    private let destination: BackupModule.Destination
    private let backupViewModel: BackupViewModel
    private var keychainAccount: String = ""

    @Published var password: String = "" {
        didSet { clearCautions() }
    }

    @Published var confirm: String = "" {
        didSet { clearCautions() }
    }

    @Published var passwordCautionState: CautionState = .none
    @Published var confirmCautionState: CautionState = .none
    @Published var secureLock: Bool = true

    @Published var passwordState: CloudPasswordState

    private(set) var shouldSaveToKeychain = false

    private let showGenerateSheetSubject = PassthroughSubject<Void, Never>()
    var showGenerateSheetPublisher: AnyPublisher<Void, Never> {
        showGenerateSheetSubject.eraseToAnyPublisher()
    }

    var isCloud: Bool {
        destination == .cloud
    }

    var isValid: Bool {
        passwordCautionState == .none && !password.isEmpty &&
            confirmCautionState == .none && !confirm.isEmpty
    }

    var processing: Bool {
        backupViewModel.processing
    }

    init(destination: BackupModule.Destination, backupViewModel: BackupViewModel) {
        self.destination = destination
        self.backupViewModel = backupViewModel

        let defaultPassphrase = AppConfig.defaultPassphrase
        if !defaultPassphrase.isEmpty {
            password = defaultPassphrase
            confirm = defaultPassphrase
        }
        
        passwordState = .init(destination: destination)
    }

    func onTapPasswordField() {
        if passwordState == .idle {
            showGenerateSheetSubject.send()
        }
    }

    func onGenerateSheetDismissed() {
        if passwordState.initial {
            passwordState = .dontSave
        }
    }

    func useGeneratedPassword() throws {
        let generated = try BackupPasswordGenerator.generate()
        password = generated
        confirm = generated
        shouldSaveToKeychain = true
        passwordState = .willSave
        secureLock = true
    }

    func setKeychainAccount(_ account: String) {
        keychainAccount = account
    }

    @MainActor
    func onTapSave() {
        performSave()
    }

    @MainActor
    private func performSave() {
        backupViewModel.set(processing: true)

        Task { [weak self] in
            guard let self else { return }

            do {
                try await saveIfNeeded()
                backupViewModel.set(password: password)
                try await backupViewModel.save()
                backupViewModel.set(processing: false)
            } catch {
                handleError(error)
            }
        }
    }

    @MainActor
    private func saveIfNeeded() async throws {
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

    @MainActor
    func validate() {
        validatePassword()
        validateConfirm()
    }

    @MainActor
    private func handleError(_ error: Error) {
        backupViewModel.set(processing: false)

        var errorDescription: String?
        if let error = error as? ValidationError {
            switch error {
            case .invalid: ()
            case .emptyKeychainAccount: errorDescription = "Keychain Empty Error!"
            }
        } else {
            errorDescription = error.localizedDescription
        }

        if let errorDescription {
            HudHelper.instance.show(banner: .error(string: errorDescription))
        }
    }

    @MainActor
    private func validatePassword() {
        do {
            try BackupCrypto.validate(passphrase: password)
            passwordCautionState = .none
        } catch {
            passwordCautionState = .caution(Caution(text: error.localizedDescription, type: .error))
        }
    }

    @MainActor
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
    enum CloudPasswordState {
        case inFiles
        case idle
        case willSave
        case dontSave
        
        var isInteractive: Bool {
            self != .idle
        }
        
        var initial: Bool {
            self == .idle
        }
        
        init(destination: BackupModule.Destination) {
            self = destination == .files ? .inFiles : .idle
        }
    }
    
    enum ValidationError: Error {
        case invalid
        case emptyKeychainAccount
    }
}
