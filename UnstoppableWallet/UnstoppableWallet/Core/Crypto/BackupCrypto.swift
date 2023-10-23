import Foundation

class BackupCrypto: Codable {
    static var defaultBackup = KdfParams(dklen: 32, n: 16384, p: 4, r: 8, salt: AppConfig.backupSalt)

    let cipher: String
    let cipherParams: CipherParams
    let cipherText: String
    let kdf: String
    let kdfParams: KdfParams
    let mac: String

    enum CodingKeys: String, CodingKey {
        case cipher
        case cipherParams = "cipherparams"
        case cipherText = "ciphertext"
        case kdf
        case kdfParams = "kdfparams"
        case mac
    }

    init(cipher: String, cipherParams: CipherParams, cipherText: String, kdf: String, kdfParams: KdfParams, mac: String) {
        self.cipher = cipher
        self.cipherParams = cipherParams
        self.cipherText = cipherText
        self.kdf = kdf
        self.kdfParams = kdfParams
        self.mac = mac
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cipher = try container.decode(String.self, forKey: .cipher)
        cipherParams = try container.decode(CipherParams.self, forKey: .cipherParams)
        cipherText = try container.decode(String.self, forKey: .cipherText)
        kdf = try container.decode(String.self, forKey: .kdf)
        kdfParams = try container.decode(KdfParams.self, forKey: .kdfParams)
        mac = try container.decode(String.self, forKey: .mac)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cipher, forKey: .cipher)
        try container.encode(cipherParams, forKey: .cipherParams)
        try container.encode(cipherText, forKey: .cipherText)
        try container.encode(kdf, forKey: .kdf)
        try container.encode(kdfParams, forKey: .kdfParams)
        try container.encode(mac, forKey: .mac)
    }
}

extension BackupCrypto {
    func decrypt(passphrase: String) throws -> Data {
        try Self.validate(passphrase: passphrase)
        // Validation data
        guard let data = Data(base64Encoded: cipherText) else {
            throw RestoreCloudModule.RestoreError.invalidBackup
        }

        // validation passphrase
        let isValid = try BackupCryptoHelper.isValid(
                macHex: mac,
                pass: passphrase,
                message: cipherText.hs.data,
                kdf: kdfParams
        )
        guard isValid else {
            throw RestoreCloudModule.RestoreError.invalidPassword
        }

        return try BackupCryptoHelper.AES128(
                operation: .decrypt,
                ivHex: cipherParams.iv,
                pass: passphrase,
                message: data,
                kdf: kdfParams
        )
    }
}

extension BackupCrypto {
    static func validate(passphrase: String) throws {
        // Validation passphrase
        guard !passphrase.isEmpty else {
            throw ValidationError.emptyPassphrase
        }
        guard passphrase.count >= BackupCloudModule.minimumPassphraseLength else {
            throw ValidationError.simplePassword
        }

        let allSatisfy = BackupCloudModule.PassphraseCharacterSet.allCases.allSatisfy { set in set.contains(passphrase) }
        if !allSatisfy {
            throw ValidationError.simplePassword
        }
    }

    static func encrypt(data: Data, passphrase: String, kdf: KdfParams = .defaultBackup) throws -> BackupCrypto {
        let iv = BackupCryptoHelper.generateInitialVector().hs.hex

        let cipherText = try BackupCryptoHelper.AES128(
                operation: .encrypt,
                ivHex: iv,
                pass: passphrase,
                message: data,
                kdf: kdf
        )

        let encodedCipherText = cipherText.base64EncodedString()
        let mac = try BackupCryptoHelper.mac(
                pass: passphrase,
                message: encodedCipherText.hs.data,
                kdf: kdf
        )

        return BackupCrypto(
                cipher: BackupCryptoHelper.defaultCypher,
                cipherParams: CipherParams(iv: iv),
                cipherText: encodedCipherText,
                kdf: BackupCryptoHelper.defaultKdf,
                kdfParams: kdf,
                mac: mac.hs.hex
        )
    }
}

extension BackupCrypto {
    enum ValidationError: Error {
        case emptyPassphrase
        case simplePassword
    }
}
