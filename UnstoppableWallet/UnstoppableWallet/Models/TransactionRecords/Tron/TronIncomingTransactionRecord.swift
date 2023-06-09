import Foundation
import TronKit
import MarketKit

class TronIncomingTransactionRecord: TronTransactionRecord {
    let from: String
    let value: TransactionValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: TransactionValue, spam: Bool = false) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
