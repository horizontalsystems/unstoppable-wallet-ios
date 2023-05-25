import Foundation

class WalletBackupCrypto: Codable {
    static var defaultBackup = KdfParams(dklen: 32, n: 16384, p: 4, r: 8, salt: "unstoppable")

    let cipher: String
    let cipherParams: CipherParams
    let cipherText: String
    let kdf: String
    let kdfParams: KdfParams
    let mac: String

    enum CodingKeys: String, CodingKey {
        case cipher
        case cipherParams = "cipherparams"
        case cipherText =  "ciphertext"
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
