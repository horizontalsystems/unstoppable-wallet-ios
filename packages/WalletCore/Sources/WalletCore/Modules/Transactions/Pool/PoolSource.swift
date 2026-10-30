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
    func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(blockchainType)
        hasher.combine(filter)
        hasher.combine(address)
    }
}
