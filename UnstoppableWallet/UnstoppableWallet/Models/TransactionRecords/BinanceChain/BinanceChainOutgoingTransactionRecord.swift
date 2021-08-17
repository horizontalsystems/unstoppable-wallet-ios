import BinanceChainKit
import CoinKit

class BinanceChainOutgoingTransactionRecord: BinanceChainTransactionRecord {
    let value: CoinValue
    let to: String
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: TransactionInfo, feeCoin: Coin, coin: Coin, sentToSelf: Bool) {
        value = CoinValue(coin: coin, value: transaction.amount)
        to = transaction.to
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, feeCoin: feeCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

}
