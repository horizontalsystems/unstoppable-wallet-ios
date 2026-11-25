import Foundation
import MarketKit

struct PoolSource {
    let token: Token?
    let account: Account
    let blockchainType: BlockchainType
    let filter: TransactionTypeFilter
    let address: String?

    var transactionSource: TransactionSource {
        TransactionSource(
            blockchainType: blockchainType,
            meta: token?.type.meta,
            accountId: account.id
        )
    }
}

extension PoolSource: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(account)
        hasher.combine(blockchainType)
        hasher.combine(filter)
        hasher.combine(address)
    }
}
