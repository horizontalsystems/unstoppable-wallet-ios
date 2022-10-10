import Foundation
import EvmKit
import MarketKit

class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    let to: String
    let value: TransactionValue
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, to: String, value: TransactionValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
