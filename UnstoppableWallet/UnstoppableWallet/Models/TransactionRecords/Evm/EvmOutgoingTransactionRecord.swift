import Foundation
import EthereumKit
import CoinKit

class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    let to: String
    let value: CoinValue
    let sentToSelf: Bool

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: Coin, amount: Decimal, to: String, token: Coin, sentToSelf: Bool) {
        self.to = to
        value = CoinValue(coin: token, value: amount)
        self.sentToSelf = sentToSelf

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

}
