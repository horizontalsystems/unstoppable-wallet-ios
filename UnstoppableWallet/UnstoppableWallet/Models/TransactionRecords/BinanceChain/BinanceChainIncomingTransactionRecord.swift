import BinanceChainKit
import MarketKit

class BinanceChainIncomingTransactionRecord: BinanceChainTransactionRecord {
    let value: TransactionValue
    let from: String

    init(source: TransactionSource, transaction: TransactionInfo, feeCoin: PlatformCoin, coin: PlatformCoin) {
        value = .coinValue(platformCoin: coin, value: transaction.amount)
        from = transaction.from

        super.init(source: source, transaction: transaction, feeCoin: feeCoin)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
