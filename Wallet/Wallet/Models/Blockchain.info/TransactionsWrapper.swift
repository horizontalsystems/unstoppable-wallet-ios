import Foundation
import ObjectMapper

struct TransactionsWrapper {
    let transactions: [BlockchainTransaction]
}

extension TransactionsWrapper: ImmutableMappable {

    init(map: Map) throws {
        transactions = try map.value("txs")
    }

}
