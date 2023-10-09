import Combine
import Foundation
import HsExtensions

class RestorePassphraseViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let service: RestorePassphraseService
    @Published public var passphraseCaution: Caution?
    @Published public var processing: Bool = false

    private let clearInputsSubject = PassthroughSubject<Void, Never>()
    private let showErrorSubject = PassthroughSubject<String, Never>()
    private let openSelectCoinsSubject = PassthroughSubject<Account, Never>()
    private let openConfigurationSubject = PassthroughSubject<RawFullBackup, Never>()
    private let successSubject = PassthroughSubject<Void, Never>()

    init(service: RestorePassphraseService) {
        self.service = service
    }

    private func clearCautions() {
        if passphraseCaution != nil {
            passphraseCaution = nil
        }
    }
}

extension RestorePassphraseViewModel {
    var clearInputsPublisher: AnyPublisher<Void, Never> {
        clearInputsSubject.eraseToAnyPublisher()
    }

    var showErrorPublisher: AnyPublisher<String, Never> {
        showErrorSubject.eraseToAnyPublisher()
    }

    var openSelectCoinsPublisher: AnyPublisher<Account, Never> {
        openSelectCoinsSubject.eraseToAnyPublisher()
    }

    var openConfigurationPublisher: AnyPublisher<RawFullBackup, Never> {
        openConfigurationSubject.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    func onChange(passphrase: String) {
        service.passphrase = passphrase
        clearCautions()
    }

    func validatePassphrase(text: String?) -> Bool {
        let validated = service.validate(text: text)
        if !validated {
            passphraseCaution = Caution(text: "backup.cloud.password.error.forbidden_symbols".localized, type: .warning)
        }
        return validated
    }

    func onTapNext() {
        passphraseCaution = nil

        processing = true
        Task { [weak self, service] in
            do {
                let result = try await service.next()
                self?.processing = false

                switch result {
                case .success:
                    self?.successSubject.send()
                case let .restoredAccount(rawBackup):
                    if rawBackup.enabledWallets.isEmpty {
                        self?.openSelectCoinsSubject.send(rawBackup.account)
                    } else {
                        self?.successSubject.send()
                    }
                case let .restoredFullBackup(rawBackup):
                    self?.openConfigurationSubject.send(rawBackup)
                }
            } catch {
                switch error as? RestoreCloudModule.RestoreError {
                case .emptyPassphrase:
                    self?.passphraseCaution = Caution(text: "backup.cloud.password.error.empty_passphrase".localized, type: .error)
                case .simplePassword:
                    self?.passphraseCaution = Caution(text: "backup.cloud.password.error.minimum_requirement".localized, type: .error)
                case .invalidPassword:
                    self?.passphraseCaution = Caution(text: "backup.cloud.password.error.invalid_password".localized, type: .error)
                case .invalidBackup:
                    self?.showErrorSubject.send("backup.cloud.password.error.invalid_backup".localized)
                case .none:
                    self?.showErrorSubject.send(error.smartDescription)
                }
                self?.processing = false
            }
        }
    }
}

extension RestorePassphraseViewModel {
    var buttonTitle: String {
        switch service.restoredBackup.source {
        case .wallet: return "button.import".localized
        case .full: return "button.continue".localized
        }
    }
}
