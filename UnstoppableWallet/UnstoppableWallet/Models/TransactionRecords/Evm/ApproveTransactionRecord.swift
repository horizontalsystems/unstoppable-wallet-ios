import EvmKit
import Foundation
import MarketKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: AppValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, spender: String, value: AppValue) {
        self.spender = spender
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainValue: AppValue? {
        value
    }
}
