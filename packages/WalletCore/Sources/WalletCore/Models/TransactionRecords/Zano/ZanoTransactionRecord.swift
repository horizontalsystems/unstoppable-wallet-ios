import Foundation
import MarketKit

class ZanoTransactionRecord: TransactionRecord {
    let fee: AppValue?
    let memo: String?

    init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: AppValue?, failed: Bool, memo: String?) {
        self.fee = fee
        self.memo = memo

        super.init(
            source: source,
            uid: uid,
            transactionHash: transactionHash,
            transactionIndex: transactionIndex,
            blockHeight: blockHeight,
            confirmationsThreshold: confirmationsThreshold,
            date: date,
            failed: failed,
            paginationRaw: transactionHash
        )
    }
}
