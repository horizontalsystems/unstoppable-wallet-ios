import Foundation
import MarketKit

struct PoolSource {
    let blockchainType: BlockchainType
    let filter: TransactionTypeFilter
    let configuredToken: ConfiguredToken?
    let bep2Symbol: String?

    var transactionSource: TransactionSource {
        TransactionSource(
                blockchainType: blockchainType,
                coinSettings: configuredToken?.coinSettings ?? [:],
                bep2Symbol: bep2Symbol
        )
    }
}

extension PoolSource: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainType)
        hasher.combine(filter)
        hasher.combine(configuredToken)
        hasher.combine(bep2Symbol)
    }

    public static func ==(lhs: PoolSource, rhs: PoolSource) -> Bool {
        lhs.blockchainType == rhs.blockchainType && lhs.filter == rhs.filter && lhs.configuredToken == rhs.configuredToken && lhs.bep2Symbol == rhs.bep2Symbol
    }

}
