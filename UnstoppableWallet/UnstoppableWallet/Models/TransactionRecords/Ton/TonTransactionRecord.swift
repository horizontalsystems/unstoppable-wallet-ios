import Foundation
import MarketKit
import TonKitKmm

class TonTransactionRecord: TransactionRecord {
    let fee: TransactionValue?
    let memo: String?

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token) {
        fee = transaction.fee.map { .coinValue(token: feeToken, value: TonAdapter.amount(kitAmount: $0)) }
        memo = transaction.memo

        super.init(
            source: source,
            uid: transaction.hash,
            transactionHash: transaction.hash,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: Date(timeIntervalSince1970: TimeInterval(transaction.timestamp)),
            failed: false
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        .completed
    }
}

extension TonTransactionRecord {
    struct Transfer {
        let address: String
        let value: TransactionValue
    }
}
