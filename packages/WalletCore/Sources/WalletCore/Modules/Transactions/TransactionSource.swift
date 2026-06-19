import MarketKit

public struct TransactionSource: Hashable {
    let blockchainType: BlockchainType
    let meta: String?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(meta)
    }

    public static func == (lhs: TransactionSource, rhs: TransactionSource) -> Bool {
        lhs.blockchainType == rhs.blockchainType && lhs.meta == rhs.meta
    }
}
