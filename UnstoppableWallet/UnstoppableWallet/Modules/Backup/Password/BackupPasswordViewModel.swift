import Combine
import Foundation

class BackupPasswordViewModel: ObservableObject {
    private let storage: IBackupPasswordStorage = BackupPasswordStorageFactory.create(type: .keychain)
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

    private(set) var generatedPassword = false
    private(set) var shouldSaveToKeychain = false

    private let showGenerateSheetSubject = PassthroughSubject<Void, Never>()
    var showGenerateSheetPublisher: AnyPublisher<Void, Never> {
        showGenerateSheetSubject.eraseToAnyPublisher()
    }

    private let showWarningSheetSubject = PassthroughSubject<Void, Never>()
    var showWarningSheetPublisher: AnyPublisher<Void, Never> {
        showWarningSheetSubject.eraseToAnyPublisher()
    }

    private let focusPasswordSubject = PassthroughSubject<Void, Never>()
    var focusPasswordPublisher: AnyPublisher<Void, Never> {
        focusPasswordSubject.eraseToAnyPublisher()
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
    }

    func onAppear() {
        let name = backupViewModel.name
        guard !name.isEmpty else { return }

        keychainAccount = name
        showGenerateSheetSubject.send()
    }

    func onGenerateSheetDismissed() {
        if !generatedPassword {
            focusPasswordSubject.send()
        }
    }

    func useGeneratedPassword() throws {
        let generated = try BackupPasswordGenerator.generate()
        password = generated
        confirm = generated
        generatedPassword = true

        switch destination {
        case .cloud:
            shouldSaveToKeychain = true
            secureLock = true
        case .files:
            shouldSaveToKeychain = false
            secureLock = false

            CopyHelper.copyAndNotify(value: password)
        }
    }

    @MainActor
    func onTapSave() {
        if destination == .files, generatedPassword {
            showWarningSheetSubject.send()
            return
        }

        performSave()
    }

    @MainActor
    func confirmSave() {
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
