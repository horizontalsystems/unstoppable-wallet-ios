import Combine
import Foundation
import HsExtensions

class RestorePassphraseViewModel: ObservableObject {
    private let service: RestorePassphraseService

    @Published var passphrase: String = AppConfig.defaultPassphrase {
        didSet {
            service.passphrase = passphrase
            clearCautions()
        }
    }

    @Published var passphraseCautionState: CautionState = .none
    @Published var processing = false

    private let showErrorSubject = PassthroughSubject<String, Never>()
    private let openSelectCoinsSubject = PassthroughSubject<Account, Never>()
    private let openConfigurationSubject = PassthroughSubject<RawFullBackup, Never>()
    private let successSubject = PassthroughSubject<AccountType, Never>()

    init(service: RestorePassphraseService) {
        self.service = service
    }

    private func clearCautions() {
        if passphraseCautionState != .none {
            passphraseCautionState = .none
        }
    }

    @MainActor
    private func handle(_ result: RestorePassphraseService.RestoreResult) {
        processing = false
        switch result {
        case let .success(accountType):
            successSubject.send(accountType)
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
    private func handle(_ error: Error) async {
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
}

extension RestorePassphraseViewModel {
    var showErrorPublisher: AnyPublisher<String, Never> {
        showErrorSubject.eraseToAnyPublisher()
    }

    var openSelectCoinsPublisher: AnyPublisher<Account, Never> {
        openSelectCoinsSubject.eraseToAnyPublisher()
    }

    var openConfigurationPublisher: AnyPublisher<RawFullBackup, Never> {
        openConfigurationSubject.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<AccountType, Never> {
        successSubject.eraseToAnyPublisher()
    }

    func onTapNext() {
        passphraseCautionState = .none
        processing = true

        Task { [weak self, service] in
            do {
                let result = try await service.next()
                await self?.handle(result)
            } catch {
                await self?.handle(error)
            }
        }
    }

    var buttonTitle: String {
        switch service.restoredBackup.source {
        case .wallet: return "button.import".localized
        case .full: return "button.continue".localized
        }
    }
}
