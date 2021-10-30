import MarketKit

struct BlockchainSetting {
    var coinType: CoinType?

    var derivation: MnemonicDerivation?
    var syncMode: SyncMode?

    init(coinType: CoinType, derivation: MnemonicDerivation?, syncMode: SyncMode?) {
        self.coinType = coinType
        self.derivation = derivation
        self.syncMode = syncMode
    }

    init(coinType: String?, derivation: String?, syncMode: String?) {
        if let coinType = coinType {
            self.coinType = BlockchainSetting.coinType(for: coinType)
        }
        if let derivation = derivation {
            self.derivation = MnemonicDerivation(rawValue: derivation)
        }
        if let syncMode = syncMode {
            self.syncMode = SyncMode(rawValue: syncMode)
        }
    }

    static func coinType(for key: String) -> CoinType? {
        switch key {
        case "bitcoin": return .bitcoin
        case "litecoin": return .litecoin
        case "bitcoinCash": return .bitcoinCash
        case "dash": return .dash
        default: return nil
        }
    }

}
