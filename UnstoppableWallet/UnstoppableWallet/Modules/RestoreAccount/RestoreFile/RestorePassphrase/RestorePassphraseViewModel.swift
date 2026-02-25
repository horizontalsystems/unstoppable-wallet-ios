import Combine
import Foundation
import HsExtensions

class RestorePassphraseViewModel: ObservableObject {
    private let appBackupProvider = Core.shared.appBackupProvider
    private let storage: IBackupPasswordStorage = BackupPasswordStorageFactory.create(type: .keychain)

    let restoredBackup: BackupModule.NamedSource

    @Published var passphrase: String = AppConfig.defaultPassphrase {
        didSet { clearCautions() }
    }

    @Published var passphraseCautionState: CautionState = .none
    @Published var processing = false

    private let focusSubject = PassthroughSubject<Bool, Never>()
    var focusPublisher: AnyPublisher<Bool, Never> {
        focusSubject.eraseToAnyPublisher()
    }

    private let unlockAndSetPasswordSubject = PassthroughSubject<String, Never>()
    var unlockAndSetPasswordPublisher: AnyPublisher<String, Never> {
        unlockAndSetPasswordSubject.eraseToAnyPublisher()
    }

    private let showErrorSubject = PassthroughSubject<String, Never>()
    private let openSelectCoinsSubject = PassthroughSubject<Account, Never>()
    private let openConfigurationSubject = PassthroughSubject<RawFullBackup, Never>()
    private let successSubject = PassthroughSubject<AccountType, Never>()

    init(restoredBackup: BackupModule.NamedSource) {
        self.restoredBackup = restoredBackup
    }

    func onAppear() {
        Task { [weak self] in
            guard let self else { return }
            let password = await storage.load(account: restoredBackup.name)
            await MainActor.run {
                if let password {
                    self.unlockAndSetPasswordSubject.send(password)
                } else {
                    self.focusSubject.send(true)
                }
            }
        }
    }

    @MainActor
    func setPassphrase(_ passphrase: String) {
        self.passphrase = passphrase
        focusSubject.send(false)
    }

    private func clearCautions() {
        if passphraseCautionState != .none {
            passphraseCautionState = .none
        }
    }

    @MainActor
    private func handle(_ result: RestoreResult) {
        processing = false
        switch result {
        case let .restoredAccount(rawBackup):
            if rawBackup.enabledWallets.isEmpty {
                openSelectCoinsSubject.send(rawBackup.account)
            } else {
                successSubject.send(rawBackup.account.type)
            }
        case let .restoredFullBackup(rawBackup):
            openConfigurationSubject.send(rawBackup)
        }
    }

    @MainActor
    private func handle(_ error: Error) {
        processing = false
        switch error as? CloudRestoreBackupListModule.RestoreError {
        case .emptyPassphrase:
            passphraseCautionState = .caution(Caution(text: "backup.cloud.password.error.empty_passphrase".localized, type: .error))
        case .simplePassword:
            passphraseCautionState = .caution(Caution(text: "backup.cloud.password.error.minimum_requirement".localized, type: .error))
        case .invalidPassword:
            passphraseCautionState = .caution(Caution(text: "backup.cloud.password.error.invalid_password".localized, type: .error))
        case .invalidBackup:
            showErrorSubject.send("backup.cloud.password.error.invalid_backup".localized)
        case .none:
            showErrorSubject.send(error.smartDescription)
        }
    }

    private func next() async throws -> RestoreResult {
        switch restoredBackup.source {
        case let .wallet(walletBackup):
            let rawBackup = try appBackupProvider.decrypt(walletBackup: walletBackup, name: restoredBackup.name, passphrase: passphrase)
            if walletBackup.version == 2 {
                appBackupProvider.restore(raws: [rawBackup])
            }
            return .restoredAccount(rawBackup)
        case let .full(fullBackup):
            let rawBackup = try appBackupProvider.decrypt(fullBackup: fullBackup, passphrase: passphrase)
            return .restoredFullBackup(rawBackup)
        }
    }
}

extension RestorePassphraseViewModel {
    enum RestoreResult {
        case restoredAccount(RawWalletBackup)
        case restoredFullBackup(RawFullBackup)
    }

    var showErrorPublisher: AnyPublisher<String, Never> { showErrorSubject.eraseToAnyPublisher() }
    var openSelectCoinsPublisher: AnyPublisher<Account, Never> { openSelectCoinsSubject.eraseToAnyPublisher() }
    var openConfigurationPublisher: AnyPublisher<RawFullBackup, Never> { openConfigurationSubject.eraseToAnyPublisher() }
    var successPublisher: AnyPublisher<AccountType, Never> { successSubject.eraseToAnyPublisher() }

    var buttonTitle: String {
        switch restoredBackup.source {
        case .wallet: return "button.import".localized
        case .full: return "button.continue".localized
        }
    }

    func onTapNext() {
        passphraseCautionState = .none
        processing = true

        Task { [weak self] in
            do {
                let result = try await self?.next()
                if let result {
                    await self?.handle(result)
                }
            } catch {
                await self?.handle(error)
            }
        }
    }
}
