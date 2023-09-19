import Foundation
import MarketKit

class RestoreCloudPassphraseService {
    private let iCloudManager: CloudBackupManager
    private let appBackupProvider: AppBackupProvider
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let restoreSettingsManager: RestoreSettingsManager

    private let restoredBackup: RestoreCloudModule.RestoredBackup

    var passphrase: String = ""

    init(iCloudManager: CloudBackupManager, appBackupProvider: AppBackupProvider, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, restoreSettingsManager: RestoreSettingsManager, item: RestoreCloudModule.RestoredBackup) {
        self.iCloudManager = iCloudManager
        self.appBackupProvider = appBackupProvider
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.restoreSettingsManager = restoreSettingsManager
        restoredBackup = item
    }

    private func createAccount(accountType: AccountType) {
        let account = accountFactory.account(type: accountType, origin: .restored, backedUp: restoredBackup.walletBackup.isManualBackedUp, name: restoredBackup.name)
        accountManager.save(account: account)

        let wallets = restoredBackup.walletBackup.enabledWallets.map {
            if !$0.settings.isEmpty {
                var restoreSettings = [RestoreSettingType: String]()
                $0.settings.forEach { key, value in
                    if let key = RestoreSettingType(rawValue: key) {
                        restoreSettings[key] = value
                    }
                }
                if let tokenQuery = TokenQuery(id: $0.tokenQueryId) {
                    restoreSettingsManager.save(settings: restoreSettings, account: account, blockchainType: tokenQuery.blockchainType)
                }
            }
            return EnabledWallet(
                tokenQueryId: $0.tokenQueryId,
                accountId: account.id,
                coinName: $0.coinName,
                coinCode: $0.coinCode,
                tokenDecimals: $0.tokenDecimals
            )
        }
        walletManager.save(enabledWallets: wallets)
    }
}

extension RestoreCloudPassphraseService {
    func validate(text: String?) -> Bool {
        PassphraseValidator.validate(text: text)
    }

    func importWallet() async throws -> RestoreResult {
        let accountType = try restoredBackup.walletBackup.crypto.accountType(type: restoredBackup.walletBackup.type, passphrase: passphrase)
        appBackupProvider.walletRestore(backup: restoredBackup, accountType: accountType)
        switch accountType {
        case .cex:
            return .success
        default:
            return .restoredAccount(RestoreCloudModule.RestoredAccount(
                name: restoredBackup.name,
                accountType: accountType,
                isManualBackedUp: restoredBackup.walletBackup.isManualBackedUp,
                showSelectCoins: restoredBackup.walletBackup.enabledWallets.isEmpty
            ))
        }
    }
}

extension RestoreCloudPassphraseService {
    enum RestoreResult {
        case restoredAccount(RestoreCloudModule.RestoredAccount)
        case success
    }
}
