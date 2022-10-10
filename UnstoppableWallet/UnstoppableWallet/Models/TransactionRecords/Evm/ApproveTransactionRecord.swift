import Foundation
import EvmKit
import MarketKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: TransactionValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, spender: String, value: TransactionValue) {
        self.spender = spender
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
