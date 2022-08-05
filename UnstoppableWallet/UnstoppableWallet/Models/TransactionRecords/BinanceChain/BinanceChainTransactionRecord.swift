import BinanceChainKit
import MarketKit

class BinanceChainTransactionRecord: TransactionRecord {
    let fee: TransactionValue
    let memo: String?

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token) {
        fee = .coinValue(token: feeToken, value: BinanceAdapter.transferFee)
        memo = transaction.memo

        super.init(
                source: source,
                uid: transaction.hash,
                transactionHash: transaction.hash,
                transactionIndex: 0,
                blockHeight: transaction.blockHeight,
                confirmationsThreshold: BinanceAdapter.confirmationsThreshold,
                date: transaction.date,
                failed: false
        )
    }

}
