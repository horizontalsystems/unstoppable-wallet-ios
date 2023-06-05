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
    private let importSubject = PassthroughSubject<RestoreCloudModule.RestoredAccount, Never>()

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

    var importPublisher: AnyPublisher<RestoreCloudModule.RestoredAccount, Never> {
        importSubject.eraseToAnyPublisher()
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
        Task {
            do {
                let restoredAccount = try await service.importWallet()
                processing = false
                importSubject.send(restoredAccount)
            } catch {
                switch (error as? RestoreCloudPassphraseService.RestoreError) {
                case .emptyPassphrase:
                    passphraseCaution = Caution(text: "backup.cloud.password.error.empty_passphrase".localized, type: .error)
                case .simplePassword:
                    passphraseCaution = Caution(text: "backup.cloud.password.error.minimum_requirement".localized, type: .error)
                case .invalidPassword:
                    passphraseCaution = Caution(text: "backup.cloud.password.error.invalid_password".localized, type: .error)
                case .invalidBackup:
                    showErrorSubject.send("backup.cloud.password.error.invalid_backup".localized)
                case .none:
                    showErrorSubject.send(error.smartDescription)
                }
                processing = false
            }
        }
    }

}
