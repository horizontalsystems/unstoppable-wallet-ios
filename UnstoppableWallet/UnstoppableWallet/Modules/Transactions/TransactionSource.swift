import MarketKit

struct TransactionSource: Hashable {
    let token: Token?
    let blockchainType: BlockchainType
    let bep2Symbol: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(token)
        hasher.combine(bep2Symbol)
    }

    static func ==(lhs: TransactionSource, rhs: TransactionSource) -> Bool {
        lhs.token == rhs.token && lhs.blockchainType == rhs.blockchainType && lhs.bep2Symbol == rhs.bep2Symbol
    }

}
