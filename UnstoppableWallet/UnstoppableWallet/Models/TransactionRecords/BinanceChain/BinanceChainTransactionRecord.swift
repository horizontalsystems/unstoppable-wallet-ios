import BinanceChainKit
import MarketKit

class BinanceChainTransactionRecord: TransactionRecord {
    let fee: AppValue
    let memo: String?

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token) {
        fee = AppValue(token: feeToken, value: BinanceAdapter.transferFee)
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

    override var rateTokens: [Token?] {
        super.rateTokens + [fee.token]
    }
}
