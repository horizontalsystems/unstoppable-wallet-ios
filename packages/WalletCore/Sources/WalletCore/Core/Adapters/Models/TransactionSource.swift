import MarketKit

public struct TransactionSource: Hashable {
    public let blockchainType: BlockchainType
    public let meta: String?

    public init(blockchainType: BlockchainType, meta: String? = nil) {
        self.blockchainType = blockchainType
        self.meta = meta
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(meta)
    }

    public static func == (lhs: TransactionSource, rhs: TransactionSource) -> Bool {
        lhs.blockchainType == rhs.blockchainType && lhs.meta == rhs.meta
    }
}
