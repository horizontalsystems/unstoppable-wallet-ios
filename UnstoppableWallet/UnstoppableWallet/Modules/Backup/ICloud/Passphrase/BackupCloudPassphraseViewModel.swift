import Combine
import Foundation
import HsExtensions

class BackupCloudPassphraseViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let service: BackupCloudPassphraseService
    @Published public var passphraseCaution: Caution?
    @Published public var passphraseConfirmationCaution: Caution?
    @Published public var processing: Bool = false

    private let clearInputsSubject = PassthroughSubject<Void, Never>()
    private let showErrorSubject = PassthroughSubject<String, Never>()
    private let finishSubject = PassthroughSubject<Void, Never>()

    init(service: BackupCloudPassphraseService) {
        self.service = service
    }

    private func clearCautions() {
        if passphraseCaution != nil {
            passphraseCaution = nil
        }

        if passphraseConfirmationCaution != nil {
            passphraseConfirmationCaution = nil
        }
    }

}

extension BackupCloudPassphraseViewModel {

    var clearInputsPublisher: AnyPublisher<Void, Never> {
        clearInputsSubject.eraseToAnyPublisher()
    }

    var showErrorPublisher: AnyPublisher<String, Never> {
        showErrorSubject.eraseToAnyPublisher()
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }


    func onChange(passphrase: String) {
        service.passphrase = passphrase
        clearCautions()
    }

    func onChange(passphraseConfirmation: String) {
        service.passphraseConfirmation = passphraseConfirmation
        clearCautions()
    }

    func validatePassphrase(text: String?) -> Bool {
        let validated = service.validate(text: text)
        if !validated {
            passphraseCaution = Caution(text: "backup.cloud.password.error.forbidden_symbols".localized, type: .warning)
        }
        return validated
    }

    func validatePassphraseConfirmation(text: String?) -> Bool {
        let validated = service.validate(text: text)
        if !validated {
            passphraseConfirmationCaution = Caution(text: "backup.cloud.password.error.forbidden_symbols".localized, type: .warning)
        }
        return validated
    }

    func onTapCreate() {
        passphraseCaution = nil
        passphraseConfirmationCaution = nil

        processing = true
        do {
            try service.createBackup()
            processing = false
            finishSubject.send(())
        } catch {
            switch error {
            case BackupCrypto.ValidationError.emptyPassphrase:
                passphraseCaution = Caution(text: "backup.cloud.password.error.empty_passphrase".localized, type: .error)
            case BackupCrypto.ValidationError.simplePassword:
                passphraseCaution = Caution(text: "backup.cloud.password.error.minimum_requirement".localized, type: .error)
            case BackupCloudPassphraseService.CreateError.invalidConfirmation:
                passphraseConfirmationCaution = Caution(text: "backup.cloud.password.confirm.error.doesnt_match".localized, type: .error)
            case BackupCloudPassphraseService.CreateError.urlNotAvailable:
                showErrorSubject.send("backup.cloud.not_available".localized)
            case BackupCloudPassphraseService.CreateError.cantSaveFile:
                showErrorSubject.send("backup.cloud.cant_create_file".localized)
            default:
                showErrorSubject.send(error.smartDescription)
            }
            processing = false
        }
    }

}
