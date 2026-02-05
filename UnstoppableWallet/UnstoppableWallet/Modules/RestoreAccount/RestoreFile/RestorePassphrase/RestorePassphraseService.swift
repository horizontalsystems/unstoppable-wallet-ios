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

    func next() async throws -> AppBackupProvider.RestoreResult {
        try appBackupProvider.restore(restoredBackup: restoredBackup, passphrase: passphrase)
    }
}
