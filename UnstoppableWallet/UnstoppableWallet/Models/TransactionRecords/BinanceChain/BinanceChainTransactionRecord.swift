import BinanceChainKit
import CoinKit

class BinanceChainTransactionRecord: TransactionRecord {
    let fee: CoinValue
    let memo: String?

    init(source: TransactionSource, transaction: TransactionInfo, feeCoin: Coin) {
        fee = CoinValue(coin: feeCoin, value: BinanceAdapter.transferFee)
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
