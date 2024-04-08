import EvmKit
import Foundation
import MarketKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: TransactionValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: TransactionValue) {
        self.from = from
        self.value = value

        let spam: Bool

        switch value {
        case let .coinValue(_, value):
            spam = value == 0
        default:
            spam = false
        }

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    override var mainValue: TransactionValue? {
        value
    }
}
