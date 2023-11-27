import Foundation
import MarketKit
import TonKitKmm

class TonIncomingTransactionRecord: TonTransactionRecord {
    let value: TransactionValue
    let from: String

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token, token: Token) {
        let tonValue: Decimal = transaction.value_.map { TonAdapter.amount(kitAmount: $0) } ?? 0
        value = .coinValue(token: token, value: tonValue)
        from = transaction.src ?? ""

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        value
    }
}
