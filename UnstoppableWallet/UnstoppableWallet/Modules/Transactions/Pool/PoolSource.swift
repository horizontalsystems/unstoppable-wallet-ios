import Foundation
import MarketKit

struct PoolSource {
    let token: Token?
    let blockchainType: BlockchainType
    let filter: TransactionTypeFilter
    let bep2Symbol: String?

    var transactionSource: TransactionSource {
        TransactionSource(
                token: token,
                blockchainType: blockchainType,
                bep2Symbol: bep2Symbol
        )
    }
}

extension PoolSource: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(blockchainType)
        hasher.combine(filter)
        hasher.combine(bep2Symbol)
    }

    public static func ==(lhs: PoolSource, rhs: PoolSource) -> Bool {
        lhs.token == rhs.token && lhs.blockchainType == rhs.blockchainType && lhs.filter == rhs.filter && lhs.bep2Symbol == rhs.bep2Symbol
    }

}
