import BinanceChainKit
import MarketKit

class BinanceChainIncomingTransactionRecord: BinanceChainTransactionRecord {
    let value: TransactionValue
    let from: String

    init(source: TransactionSource, transaction: TransactionInfo, feeToken: Token, token: Token) {
        value = .coinValue(token: token, value: transaction.amount)
        from = transaction.from

        super.init(source: source, transaction: transaction, feeToken: feeToken)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
