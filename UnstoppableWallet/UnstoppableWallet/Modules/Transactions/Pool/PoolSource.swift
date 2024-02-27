import Foundation
import MarketKit

struct PoolSource {
    let token: Token?
    let blockchainType: BlockchainType
    let filter: TransactionTypeFilter
    let address: String?

    var transactionSource: TransactionSource {
        TransactionSource(
            blockchainType: blockchainType,
            meta: token?.type.meta
        )
    }
}

extension PoolSource: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(blockchainType)
        hasher.combine(filter)
        hasher.combine(address)
    }

    public static func == (lhs: PoolSource, rhs: PoolSource) -> Bool {
        lhs.token == rhs.token && lhs.blockchainType == rhs.blockchainType && lhs.filter == rhs.filter && lhs.address == rhs.address
    }
}
