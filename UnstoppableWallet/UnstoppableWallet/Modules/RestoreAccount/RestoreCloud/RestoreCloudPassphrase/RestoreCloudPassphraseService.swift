import Foundation

class RestoreCloudPassphraseService {
    private let iCloudManager: CloudAccountBackupManager

    private let restoredBackup: RestoreCloudModule.RestoredBackup

    var passphrase: String = ""

    init(iCloudManager: CloudAccountBackupManager, item: RestoreCloudModule.RestoredBackup) {
        self.iCloudManager = iCloudManager
        self.restoredBackup = item
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

            return .restoredAccount(RestoreCloudModule.RestoredAccount(
                    name: restoredBackup.name,
                    accountType: accountType,
                    isManualBackedUp: restoredBackup.walletBackup.isManualBackedUp
            ))
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
