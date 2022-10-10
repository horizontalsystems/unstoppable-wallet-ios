import Foundation
import EvmKit
import MarketKit

class UnknownSwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let valueIn: TransactionValue?
    let valueOut: TransactionValue?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, exchangeAddress: String, valueIn: TransactionValue?, valueOut: TransactionValue?) {
        self.exchangeAddress = exchangeAddress
        self.valueIn = valueIn
        self.valueOut = valueOut

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

}
