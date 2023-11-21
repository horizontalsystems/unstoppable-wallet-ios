import Foundation
import MarketKit
import TonKitKmm

class TonOutgoingTransactionRecord: TonTransactionRecord {
    let value: TransactionValue
    let to: String
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token, token: Token, sentToSelf: Bool) {
        let rawTonValue: Decimal = transaction.value_.flatMap { Decimal(string: $0) } ?? 0
        let tonValue = rawTonValue / TonAdapter.coinRate
        value = .coinValue(token: token, value: Decimal(sign: .minus, exponent: tonValue.exponent, significand: tonValue.significand))
        to = transaction.dest ?? ""
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        value
    }
}
