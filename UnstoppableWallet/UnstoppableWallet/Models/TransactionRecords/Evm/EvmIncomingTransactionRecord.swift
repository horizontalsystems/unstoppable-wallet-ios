import Foundation
import EvmKit
import MarketKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: TransactionValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: TransactionValue) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
