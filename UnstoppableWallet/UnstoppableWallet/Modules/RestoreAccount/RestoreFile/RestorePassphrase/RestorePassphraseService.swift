import Foundation
import MarketKit

class RestorePassphraseService {
    private let iCloudManager: CloudBackupManager
    private let appBackupProvider: AppBackupProvider
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let restoreSettingsManager: RestoreSettingsManager

    let restoredBackup: BackupModule.NamedSource
    var passphrase: String = ""

    init(iCloudManager: CloudBackupManager, appBackupProvider: AppBackupProvider, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, restoreSettingsManager: RestoreSettingsManager, restoredBackup: BackupModule.NamedSource) {
        self.iCloudManager = iCloudManager
        self.appBackupProvider = appBackupProvider
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.restoreSettingsManager = restoreSettingsManager
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
            if walletBackup.version == 2 {  // in 2th version we use enabled_wallets and just restore wallet.
                appBackupProvider.restore(raws: [rawBackup])
            }
            switch rawBackup.account.type {
            case .cex:
                return .success
            default:
                return .restoredAccount(rawBackup)
            }
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
        case success
    }
}
