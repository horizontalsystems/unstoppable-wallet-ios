import Foundation

class WalletBackup: Codable {
    let crypto: WalletBackupCrypto
    let id: String
    let type: AccountType.Abstract
    let version: Int

    enum CodingKeys: String, CodingKey {
        case crypto
        case id
        case type
        case version
    }

    init(crypto: WalletBackupCrypto, id: String, type: AccountType.Abstract, version: Int) {
        self.crypto = crypto
        self.id = id
        self.type = type
        self.version = version
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        crypto = try container.decode(WalletBackupCrypto.self, forKey: .crypto)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(AccountType.Abstract.self, forKey: .type)
        version = try container.decode(Int.self, forKey: .version)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(crypto, forKey: .crypto)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(version, forKey: .version)
    }

}

