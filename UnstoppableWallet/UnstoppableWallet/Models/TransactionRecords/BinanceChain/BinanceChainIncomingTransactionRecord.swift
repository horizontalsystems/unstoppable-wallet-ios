import BinanceChainKit
import MarketKit

class BinanceChainIncomingTransactionRecord: BinanceChainTransactionRecord {
    let value: AppValue
    let from: String

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token, token: Token) {
        value = AppValue(token: token, value: transaction.amount)
        from = transaction.from

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: AppValue? {
        value
    }
}
