import EvmKit
import Foundation
import MarketKit

class ApproveTransactionRecord: EvmTransactionRecord, IApproveTransaction {
    let spender: String
    let value: AppValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, spender: String, value: AppValue, protected: Bool) {
        self.spender = spender
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true, protected: protected)
    }

    override var mainValue: AppValue? {
        value
    }
}

protocol IApproveTransaction {
    var spender: String { get }
    var value: AppValue { get }
}
