import Foundation
import MarketKit
import TonKitKmm

class TonOutgoingTransactionRecord: TonTransactionRecord {
    let transfers: [Transfer]
    let totalValue: TransactionValue

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token, token: Token) {
        var totalAmount: Decimal = 0

        transfers = transaction.transfers.map { transfer in
            let tonValue = TonAdapter.amount(kitAmount: transfer.amount)
            let value = Decimal(sign: .minus, exponent: tonValue.exponent, significand: tonValue.significand)

            totalAmount += value

            return Transfer(
                address: transfer.dest,
                value: .coinValue(token: token, value: value)
            )
        }

        totalValue = .coinValue(token: token, value: totalAmount)

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        totalValue
    }
}
