import BinanceChainKit
import Foundation
import MarketKit

class BinanceChainOutgoingTransactionRecord: BinanceChainTransactionRecord {
    let value: AppValue
    let to: String
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token, token: Token, sentToSelf: Bool) {
        value = AppValue(token: token, value: Decimal(sign: .minus, exponent: transaction.amount.exponent, significand: transaction.amount.significand))
        to = transaction.to
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: AppValue? {
        value
    }
}
