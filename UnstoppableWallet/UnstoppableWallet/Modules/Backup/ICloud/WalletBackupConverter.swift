import Foundation

class WalletBackupConverter {
    private static let version = 1

    static func encode(accountType: AccountType, isManualBackedUp: Bool, passphrase: String) throws -> Data {
        let message = accountType.uniqueId(hashed: false)
        let iv = BackupCryptoHelper.generateInitialVector().hs.hex

        let cipherText = try BackupCryptoHelper.AES128(
                operation: .encrypt,
                ivHex: iv,
                pass: passphrase,
                message: message,
                kdf: .defaultBackup
        )
        let encodedCipherText = cipherText.base64EncodedString()
        let mac = try BackupCryptoHelper.mac(
                pass: passphrase,
                message: encodedCipherText.hs.data,
                kdf: .defaultBackup
        )

        let crypto = WalletBackupCrypto(
                cipher: BackupCryptoHelper.defaultCypher,
                cipherParams: CipherParams(iv: iv),
                cipherText: encodedCipherText,
                kdf: BackupCryptoHelper.defaultKdf,
                kdfParams: .defaultBackup,
                mac: mac.hs.hex)
        let backup = WalletBackup(
                crypto: crypto,
                id: accountType.uniqueId().hs.hex,
                type: AccountType.Abstract(accountType),
                isManualBackedUp: isManualBackedUp,
                version: Self.version,
                timestamp: Date().timeIntervalSince1970
        )
        return try JSONEncoder().encode(backup)

    }

    static func decode(data: Data, passphrase: String) throws -> AccountType {
        let backup = try JSONDecoder().decode(WalletBackup.self, from: data)

        guard let message = Data(base64Encoded: backup.crypto.cipherText) else {
            throw CodingError.cantDecodeCipherText
        }

        let decryptData = try BackupCryptoHelper.AES128(
                operation: .decrypt,
                ivHex: backup.crypto.cipherParams.iv,
                pass: passphrase,
                message: message,
                kdf: .defaultBackup)

        guard let accountType = AccountType.decode(uniqueId: decryptData, type: backup.type) else {
            throw CodingError.cantDecodeAccountType
        }

        return accountType
    }

}

extension WalletBackupConverter {

    enum CodingError: Error {
        case cantDecodeCipherText
        case cantDecodeAccountType
    }

}
