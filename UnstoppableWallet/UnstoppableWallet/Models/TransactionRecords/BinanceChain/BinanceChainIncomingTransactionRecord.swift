import BinanceChainKit
import CoinKit

class BinanceChainIncomingTransactionRecord: BinanceChainTransactionRecord {
    let value: CoinValue
    let from: String

    init(source: TransactionSource, transaction: TransactionInfo, feeCoin: Coin, coin: Coin) {
        value = CoinValue(coin: coin, value: transaction.amount)
        from = transaction.from

        super.init(source: source, transaction: transaction, feeCoin: feeCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

}
