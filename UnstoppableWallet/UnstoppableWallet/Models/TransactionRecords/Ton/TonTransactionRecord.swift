import Foundation
import MarketKit
import TonKitKmm

class TonTransactionRecord: TransactionRecord {
    let fee: TransactionValue

    init(source: TransactionSource, transaction: TonTransaction, feeToken: Token) {
        fee = .coinValue(token: feeToken, value: 0.00001) // todo

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
