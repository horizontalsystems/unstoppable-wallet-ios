import BinanceChainKit
import CoinKit

class BinanceChainOutgoingTransactionRecord: BinanceChainTransactionRecord {
    let value: CoinValue
    let to: String
    let sentToSelf: Bool

    init(transaction: TransactionInfo, feeCoin: Coin, coin: Coin, sentToSelf: Bool) {
        value = CoinValue(coin: coin, value: transaction.amount)
        to = transaction.to
        self.sentToSelf = sentToSelf

        super.init(transaction: transaction, feeCoin: feeCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

}
