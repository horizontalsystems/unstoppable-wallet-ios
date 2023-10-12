import Foundation

class WalletBackup: Codable {
    let crypto: BackupCrypto
    let id: String
    let type: AccountType.Abstract
    let isManualBackedUp: Bool
    let isFileBackedUp: Bool
    let version: Int
    let timestamp: TimeInterval?
    let enabledWallets: [EnabledWallet]

    enum CodingKeys: String, CodingKey {
        case crypto
        case enabledWallets = "enabled_wallets"
        case id
        case type
        case isManualBackedUp = "manual_backup"
        case isFileBackedUp = "file_backup"
        case version
        case timestamp
    }

    init(crypto: BackupCrypto, enabledWallets: [EnabledWallet], id: String, type: AccountType.Abstract, isManualBackedUp: Bool, isFileBackedUp: Bool, version: Int, timestamp: TimeInterval) {
        self.crypto = crypto
        self.enabledWallets = enabledWallets
        self.id = id
        self.type = type
        self.isManualBackedUp = isManualBackedUp
        self.isFileBackedUp = isFileBackedUp
        self.version = version
        self.timestamp = timestamp
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        crypto = try container.decode(BackupCrypto.self, forKey: .crypto)
        enabledWallets = (try? container.decode([EnabledWallet].self, forKey: .enabledWallets)) ?? []
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(AccountType.Abstract.self, forKey: .type)
        let isManualBackedUp = try? container.decode(Bool.self, forKey: .isManualBackedUp)
        self.isManualBackedUp = isManualBackedUp ?? false
        let isFileBackedUp = try? container.decode(Bool.self, forKey: .isFileBackedUp)
        self.isFileBackedUp = isFileBackedUp ?? false
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
        try container.encode(isFileBackedUp, forKey: .isFileBackedUp)
        try container.encode(version, forKey: .version)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

extension WalletBackup {
    struct Settings: Codable {
        let type: String
        let value: String
    }

    struct EnabledWallet: Codable {
        let tokenQueryId: String
        let coinName: String?
        let coinCode: String?
        let tokenDecimals: Int?
        let settings: [String: String]

        enum CodingKeys: String, CodingKey {
            case tokenQueryId = "token_query_id"
            case coinName = "coin_name"
            case coinCode = "coin_code"
            case tokenDecimals = "decimals"
            case settings
        }

        init(tokenQueryId: String, coinName: String?, coinCode: String?, tokenDecimals: Int?, settings: [String: String]) {
            self.tokenQueryId = tokenQueryId
            self.coinName = coinName
            self.coinCode = coinCode
            self.tokenDecimals = tokenDecimals
            self.settings = settings
        }

        init(_ wallet: Wallet, settings: [String: String]) {
            tokenQueryId = wallet.token.tokenQuery.id
            coinName = wallet.coin.name
            coinCode = wallet.coin.code
            tokenDecimals = wallet.decimals
            self.settings = settings
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let tokenQueryId = try container.decode(String.self, forKey: .tokenQueryId)
            let coinName = try? container.decode(String.self, forKey: .coinName)
            let coinCode = try container.decode(String.self, forKey: .coinCode)
            let tokenDecimals = try container.decode(Int.self, forKey: .tokenDecimals)
            let settings = try? container.decode([String: String].self, forKey: .settings)

            self.init(tokenQueryId: tokenQueryId, coinName: coinName, coinCode: coinCode, tokenDecimals: tokenDecimals, settings: settings ?? [:])
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(tokenQueryId, forKey: .tokenQueryId)
            try container.encode(coinName, forKey: .coinName)
            try container.encode(coinCode, forKey: .coinCode)
            try container.encode(tokenDecimals, forKey: .tokenDecimals)
            if !settings.isEmpty {
                try container.encode(settings, forKey: .settings)
            }
        }
    }
}
