public enum CoinSettingType: String, CaseIterable {
    case derivation
    case bitcoinCashCoinType
}

typealias CoinSettings = [CoinSettingType: String]

extension CoinSettings: Identifiable {
    public typealias ID = String

    public init(id: ID) {
        var settings = CoinSettings()

        let chunks = id.split(separator: "|")

        for chunk in chunks {
            let subChunks = chunk.split(separator: ":")

            guard subChunks.count == 2 else {
                continue
            }

            guard let type = CoinSettingType(rawValue: String(subChunks[0])) else {
                continue
            }

            settings[type] = String(subChunks[1])
        }

        self = settings
    }

    public var id: ID {
        var chunks = [String]()

        for type in CoinSettingType.allCases {
            if let value = self[type] {
                chunks.append("\(type.rawValue):\(value)")
            }
        }

        return chunks.joined(separator: "|")
    }

}

extension CoinSettings {

    var derivation: MnemonicDerivation? {
        self[.derivation].flatMap { MnemonicDerivation(rawValue: $0) }
    }

    var bitcoinCashCoinType: BitcoinCashCoinType? {
        self[.bitcoinCashCoinType].flatMap { BitcoinCashCoinType(rawValue: $0) }
    }

}
