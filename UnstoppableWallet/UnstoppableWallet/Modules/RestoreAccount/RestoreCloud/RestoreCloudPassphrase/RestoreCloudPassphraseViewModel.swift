import Combine
import Foundation
import HsExtensions

class RestoreCloudPassphraseViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let service: RestoreCloudPassphraseService
    @Published public var passphraseCaution: Caution?
    @Published public var processing: Bool = false

    private let clearInputsSubject = PassthroughSubject<Void, Never>()
    private let showErrorSubject = PassthroughSubject<String, Never>()
    private let openSelectCoinsSubject = PassthroughSubject<RestoreCloudModule.RestoredAccount, Never>()
    private let successSubject = PassthroughSubject<Void, Never>()

    init(service: RestoreCloudPassphraseService) {
        self.service = service
    }

    private func clearCautions() {
        if passphraseCaution != nil {
            passphraseCaution = nil
        }
    }

}

extension RestoreCloudPassphraseViewModel {

    var clearInputsPublisher: AnyPublisher<Void, Never> {
        clearInputsSubject.eraseToAnyPublisher()
    }

    var showErrorPublisher: AnyPublisher<String, Never> {
        showErrorSubject.eraseToAnyPublisher()
    }

    var openSelectCoinsPublisher: AnyPublisher<RestoreCloudModule.RestoredAccount, Never> {
        openSelectCoinsSubject.eraseToAnyPublisher()
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

    func onTapImport() {
        passphraseCaution = nil

        processing = true
        Task { [weak self, service] in
            do {
                let result = try await service.importWallet()
                self?.processing = false

                switch result {
                case .success: self?.successSubject.send()
                case .restoredAccount(let account): self?.openSelectCoinsSubject.send(account)
                }
            } catch {
                switch (error as? RestoreCloudPassphraseService.RestoreError) {
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
