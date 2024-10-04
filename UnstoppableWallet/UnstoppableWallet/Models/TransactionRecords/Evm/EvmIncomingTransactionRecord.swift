import EvmKit
import Foundation
import MarketKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: AppValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: AppValue) {
        self.from = from
        self.value = value

        let spam: Bool

        switch value.kind {
        case .token:
            spam = value.value == 0
        default:
            spam = false
        }

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    override var mainValue: AppValue? {
        value
    }
}
