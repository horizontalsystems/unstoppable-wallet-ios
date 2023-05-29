import Foundation

class ICloudBackupPassphraseService {
    private let minimumPassphraseLength = 8

    private let iCloudManager: CloudAccountBackupManager
    private let account: Account
    private let name: String

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(iCloudManager: CloudAccountBackupManager, account: Account, name: String) {
        self.iCloudManager = iCloudManager
        self.account = account
        self.name = name
    }

}

extension ICloudBackupPassphraseService {

    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
    }

    func createBackup() async throws {
        guard !passphrase.isEmpty else {
            throw CreateError.emptyPassphrase
        }

        guard passphrase.count >= minimumPassphraseLength else {
            throw CreateError.tooShort
        }

        guard passphrase == passphraseConfirmation else {
            throw CreateError.invalidConfirmation
        }

        do {
            try await iCloudManager.save(accountType: account.type, passphrase: passphrase, name: name)
        } catch {
            if case .urlNotAvailable = error as? CloudAccountBackupManager.BackupError {
                throw CreateError.urlNotAvailable
            }
            throw CreateError.cantSaveFile(error)
        }
    }

}

extension ICloudBackupPassphraseService {

    enum CreateError: Error {
        case emptyPassphrase
        case tooShort
        case invalidConfirmation
        case urlNotAvailable
        case cantSaveFile(Error)
    }

}
