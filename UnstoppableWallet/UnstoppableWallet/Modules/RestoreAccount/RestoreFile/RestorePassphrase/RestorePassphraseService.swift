import Foundation
import MarketKit

class RestorePassphraseService {
    private let appBackupProvider: AppBackupProvider

    let restoredBackup: BackupModule.NamedSource
    var passphrase: String = ""

    init(appBackupProvider: AppBackupProvider, restoredBackup: BackupModule.NamedSource) {
        self.appBackupProvider = appBackupProvider
        self.restoredBackup = restoredBackup
    }
}

extension RestorePassphraseService {
    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
    }

    func next() async throws -> RestoreResult {
        switch restoredBackup.source {
        case let .wallet(walletBackup):
            let rawBackup = try appBackupProvider.decrypt(walletBackup: walletBackup, name: restoredBackup.name, passphrase: passphrase)
            if walletBackup.version == 2 { // in 2th version we use enabled_wallets and just restore wallet.
                appBackupProvider.restore(raws: [rawBackup])
            }

            return .restoredAccount(rawBackup)
        case let .full(fullBackup):
            let rawBackup = try appBackupProvider.decrypt(fullBackup: fullBackup, passphrase: passphrase)
            return .restoredFullBackup(rawBackup)
        }
    }
}

extension RestorePassphraseService {
    enum RestoreResult {
        case restoredAccount(RawWalletBackup)
        case restoredFullBackup(RawFullBackup)
        case success(AccountType)
    }
}
