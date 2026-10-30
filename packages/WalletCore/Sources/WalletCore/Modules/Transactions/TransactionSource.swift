import MarketKit

public struct TransactionSource: Hashable {
    public let blockchainType: BlockchainType
    let meta: String?

    public init(blockchainType: BlockchainType, meta: String?) {
        self.blockchainType = blockchainType
        self.meta = meta
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(meta)
    }
}
