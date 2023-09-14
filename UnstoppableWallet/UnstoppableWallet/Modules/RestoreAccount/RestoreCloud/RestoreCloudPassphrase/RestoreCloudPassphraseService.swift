import Foundation

class RestoreCloudPassphraseService {
    private let iCloudManager: CloudAccountBackupManager
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    private let restoredBackup: RestoreCloudModule.RestoredBackup

    var passphrase: String = ""

    init(iCloudManager: CloudAccountBackupManager, accountFactory: AccountFactory, accountManager: AccountManager, walletManager: WalletManager, item: RestoreCloudModule.RestoredBackup) {
        self.iCloudManager = iCloudManager
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.walletManager = walletManager
        restoredBackup = item
    }

    private func createAccount(accountType: AccountType) {
        let account = accountFactory.account(type: accountType, origin: .restored, backedUp: restoredBackup.walletBackup.isManualBackedUp, name: restoredBackup.name)
        accountManager.save(account: account)

        let wallets = restoredBackup.walletBackup.enabledWallets.map {
            EnabledWallet(
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
        let crypto = restoredBackup.walletBackup.crypto

        guard !passphrase.isEmpty else {
            throw RestoreError.emptyPassphrase
        }
        guard passphrase.count >= BackupCloudModule.minimumPassphraseLength else {
            throw RestoreError.simplePassword
        }

        let allSatisfy = BackupCloudModule.PassphraseCharacterSet.allCases.allSatisfy { set in set.contains(passphrase) }
        if !allSatisfy {
            throw RestoreError.simplePassword
        }

        guard let walletData = Data(base64Encoded: crypto.cipherText) else {
            throw RestoreError.invalidBackup
        }

        let isValid = (try? BackupCryptoHelper.isValid(
                macHex: crypto.mac,
                pass: passphrase,
                message: crypto.cipherText.hs.data,
                kdf: crypto.kdfParams
        )) ?? false

        guard isValid else {
            throw RestoreError.invalidPassword
        }

        do {
            let data = try BackupCryptoHelper.AES128(
                    operation: .decrypt,
                    ivHex: crypto.cipherParams.iv,
                    pass: passphrase,
                    message: walletData,
                    kdf: crypto.kdfParams)

            guard let accountType = AccountType.decode(uniqueId: data, type: restoredBackup.walletBackup.type) else {
                throw RestoreError.invalidBackup
            }

            switch accountType {
            case .cex:
                let account = accountFactory.account(
                        type: accountType,
                        origin: .restored,
                        backedUp: restoredBackup.walletBackup.isManualBackedUp,
                        name: restoredBackup.name
                )
                accountManager.save(account: account)
                return .success
            default:
                createAccount(accountType: accountType)
                return .restoredAccount(RestoreCloudModule.RestoredAccount(
                        name: restoredBackup.name,
                        accountType: accountType,
                        isManualBackedUp: restoredBackup.walletBackup.isManualBackedUp,
                        showSelectCoins: restoredBackup.walletBackup.enabledWallets.isEmpty
                ))
            }
        } catch {
            throw RestoreError.invalidBackup
        }
    }

}

extension RestoreCloudPassphraseService {

    enum RestoreError: Error {
        case emptyPassphrase
        case simplePassword
        case invalidPassword
        case invalidBackup
    }

    enum RestoreResult {
        case restoredAccount(RestoreCloudModule.RestoredAccount)
        case success
    }

}
