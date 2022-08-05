import MarketKit

struct TransactionSource: Hashable {
    let blockchainType: BlockchainType
    let coinSettings: CoinSettings
    let bep2Symbol: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(coinSettings)

        if let bep2Symbol = bep2Symbol {
            hasher.combine(bep2Symbol)
        }
    }

    static func ==(lhs: TransactionSource, rhs: TransactionSource) -> Bool {
        lhs.blockchainType == rhs.blockchainType && lhs.coinSettings == rhs.coinSettings && lhs.bep2Symbol == rhs.bep2Symbol
    }

}
