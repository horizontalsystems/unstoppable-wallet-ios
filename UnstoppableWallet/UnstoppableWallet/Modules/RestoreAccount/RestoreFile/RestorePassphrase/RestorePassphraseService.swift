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
            let accountType = try walletBackup
                .crypto
                .accountType(type: walletBackup.type, passphrase: passphrase)
            let restoredBackup = RestoreCloudModule.RestoredBackup(name: restoredBackup.name, walletBackup: walletBackup)
            appBackupProvider.walletRestore(backup: restoredBackup, accountType: accountType)
            switch accountType {
            case .cex:
                return .success
            default:
                return .restoredAccount(RestoreCloudModule.RestoredAccount(
                        name: restoredBackup.name,
                        accountType: accountType,
                        isManualBackedUp: walletBackup.isManualBackedUp,
                        isFileBackedUp: walletBackup.isFileBackedUp,
                        showSelectCoins: walletBackup.enabledWallets.isEmpty
                ))
            }
        case .full:
            print("Lets try!")
            return .success
        }
    }
}

extension RestorePassphraseService {
    enum RestoreResult {
        case restoredAccount(RestoreCloudModule.RestoredAccount)
        case source(BackupModule.Source)
        case success
    }
}
