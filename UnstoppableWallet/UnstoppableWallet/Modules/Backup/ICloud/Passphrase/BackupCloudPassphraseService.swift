import Foundation

class BackupCloudPassphraseService {
    private let iCloudManager: CloudBackupManager
    private let account: Account
    private let name: String

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(iCloudManager: CloudBackupManager, account: Account, name: String) {
        self.iCloudManager = iCloudManager
        self.account = account
        self.name = name
    }

}

extension BackupCloudPassphraseService {

    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
    }

    func createBackup() throws {
        try BackupCrypto.validate(passphrase: passphrase)

        guard passphrase == passphraseConfirmation else {
            throw CreateError.invalidConfirmation
        }

        do {
            try iCloudManager.save(account: account, passphrase: passphrase, name: name)
        } catch {
            if case .urlNotAvailable = error as? CloudBackupManager.BackupError {
                throw CreateError.urlNotAvailable
            }
            throw CreateError.cantSaveFile(error)
        }
    }

}

extension BackupCloudPassphraseService {

    enum CreateError: Error {
        case invalidConfirmation
        case urlNotAvailable
        case cantSaveFile(Error)
    }

}
