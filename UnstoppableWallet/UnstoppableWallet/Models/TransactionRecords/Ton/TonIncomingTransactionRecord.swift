import Foundation
import MarketKit
import TonKitKmm

class TonIncomingTransactionRecord: TonTransactionRecord {
    let value: TransactionValue
    let from: String

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token, token: Token) {
        let rawTonValue: Decimal = transaction.value_.flatMap { Decimal(string: $0) } ?? 0
        let tonValue = rawTonValue / TonAdapter.coinRate
        value = .coinValue(token: token, value: tonValue)
        from = transaction.src ?? ""

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        value
    }
}
