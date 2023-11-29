import Foundation
import MarketKit
import TonKitKmm

class TonIncomingTransactionRecord: TonTransactionRecord {
    let transfer: Transfer?

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token, token: Token) {
        transfer = transaction.transfers.first.map { transfer in
            Transfer(
                address: transfer.src,
                value: .coinValue(token: token, value: TonAdapter.amount(kitAmount: transfer.amount))
            )
        }

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        transfer?.value
    }
}
