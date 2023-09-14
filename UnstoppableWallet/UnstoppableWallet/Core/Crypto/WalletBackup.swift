import Foundation

class WalletBackup: Codable {
    let crypto: WalletBackupCrypto
    let id: String
    let type: AccountType.Abstract
    let isManualBackedUp: Bool
    let version: Int
    let timestamp: TimeInterval?
    let enabledWallets: [EnabledWallet]

    enum CodingKeys: String, CodingKey {
        case crypto
        case enabledWallets = "enabled_wallets"
        case id
        case type
        case isManualBackedUp = "manual_backup"
        case version
        case timestamp
    }

    init(crypto: WalletBackupCrypto, enabledWallets: [EnabledWallet], id: String, type: AccountType.Abstract, isManualBackedUp: Bool, version: Int, timestamp: TimeInterval) {
        self.crypto = crypto
        self.enabledWallets = enabledWallets
        self.id = id
        self.type = type
        self.isManualBackedUp = isManualBackedUp
        self.version = version
        self.timestamp = timestamp.rounded()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        crypto = try container.decode(WalletBackupCrypto.self, forKey: .crypto)
        enabledWallets = (try? container.decode([EnabledWallet].self, forKey: .enabledWallets)) ?? []
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(AccountType.Abstract.self, forKey: .type)
        let isManualBackedUp = try? container.decode(Bool.self, forKey: .isManualBackedUp)
        self.isManualBackedUp = isManualBackedUp ?? false
        version = try container.decode(Int.self, forKey: .version)
        timestamp = try? container.decode(TimeInterval.self, forKey: .timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(crypto, forKey: .crypto)
        try container.encode(enabledWallets, forKey: .enabledWallets)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(isManualBackedUp, forKey: .isManualBackedUp)
        try container.encode(version, forKey: .version)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

extension WalletBackup {
    struct EnabledWallet: Codable {
        let tokenQueryId: String
        let coinName: String?
        let coinCode: String?
        let tokenDecimals: Int?

        enum CodingKeys: String, CodingKey {
            case tokenQueryId = "token_query_id"
            case coinName = "coin_name"
            case coinCode = "coin_code"
            case tokenDecimals = "decimals"
        }

        init(tokenQueryId: String, coinName: String?, coinCode: String?, tokenDecimals: Int?) {
            self.tokenQueryId = tokenQueryId
            self.coinName = coinName
            self.coinCode = coinCode
            self.tokenDecimals = tokenDecimals
        }

        init(_ wallet: Wallet) {
            tokenQueryId = wallet.token.tokenQuery.id
            coinName = wallet.coin.name
            coinCode = wallet.coin.code
            tokenDecimals = wallet.decimals
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let tokenQueryId = try container.decode(String.self, forKey: .tokenQueryId)
            let coinName = try? container.decode(String.self, forKey: .coinName)
            let coinCode = try container.decode(String.self, forKey: .coinCode)
            let tokenDecimals = try container.decode(Int.self, forKey: .tokenDecimals)

            self.init(tokenQueryId: tokenQueryId, coinName: coinName, coinCode: coinCode, tokenDecimals: tokenDecimals)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(tokenQueryId, forKey: .tokenQueryId)
            try container.encode(coinName, forKey: .coinName)
            try container.encode(coinCode, forKey: .coinCode)
            try container.encode(tokenDecimals, forKey: .tokenDecimals)
        }
    }
}
