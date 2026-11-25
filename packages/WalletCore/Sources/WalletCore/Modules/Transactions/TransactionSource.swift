import MarketKit

public struct TransactionSource: Hashable {
    public let blockchainType: BlockchainType
    let meta: String?
    /// The account whose wallet the records belong to: one token of one chain in two accounts is two sources.
    public let accountId: String

    public init(blockchainType: BlockchainType, meta: String?, accountId: String) {
        self.blockchainType = blockchainType
        self.meta = meta
        self.accountId = accountId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(meta)
        hasher.combine(accountId)
    }
}
