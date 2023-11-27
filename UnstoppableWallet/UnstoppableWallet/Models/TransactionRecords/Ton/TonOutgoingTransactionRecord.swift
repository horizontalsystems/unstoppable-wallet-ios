import Foundation
import MarketKit
import TonKitKmm

class TonOutgoingTransactionRecord: TonTransactionRecord {
    let value: TransactionValue
    let to: String
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token, token: Token, sentToSelf: Bool) {
        let tonValue: Decimal = transaction.value_.map { TonAdapter.amount(kitAmount: $0) } ?? 0
        value = .coinValue(token: token, value: Decimal(sign: .minus, exponent: tonValue.exponent, significand: tonValue.significand))
        to = transaction.dest ?? ""
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        value
    }
}
