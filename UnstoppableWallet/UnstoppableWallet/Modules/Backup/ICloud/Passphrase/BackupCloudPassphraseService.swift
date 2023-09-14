import Foundation

class BackupCloudPassphraseService {
    private let iCloudManager: CloudAccountBackupManager
    private let walletManager: WalletManager
    private let account: Account
    private let name: String

    var passphrase: String = ""
    var passphraseConfirmation: String = ""

    init(iCloudManager: CloudAccountBackupManager, walletManager: WalletManager, account: Account, name: String) {
        self.iCloudManager = iCloudManager
        self.walletManager = walletManager
        self.account = account
        self.name = name
    }

}

extension BackupCloudPassphraseService {

    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
    }

    func createBackup() throws {
        guard !passphrase.isEmpty else {
            throw CreateError.emptyPassphrase
        }

        guard passphrase.count >= BackupCloudModule.minimumPassphraseLength else {
            throw CreateError.simplePassword
        }

        let allSatisfy = BackupCloudModule.PassphraseCharacterSet.allCases.allSatisfy { set in set.contains(passphrase) }
        if !allSatisfy {
            throw CreateError.simplePassword
        }

        guard passphrase == passphraseConfirmation else {
            throw CreateError.invalidConfirmation
        }

        do {
            let wallets = App.shared.walletManager.wallets(account: account)
            try iCloudManager.save(accountType: account.type, wallets: wallets, isManualBackedUp: account.backedUp, passphrase: passphrase, name: name)
        } catch {
            if case .urlNotAvailable = error as? CloudAccountBackupManager.BackupError {
                throw CreateError.urlNotAvailable
            }
            throw CreateError.cantSaveFile(error)
        }
    }

}

extension BackupCloudPassphraseService {

    enum CreateError: Error {
        case emptyPassphrase
        case simplePassword
        case invalidConfirmation
        case urlNotAvailable
        case cantSaveFile(Error)
    }

}
