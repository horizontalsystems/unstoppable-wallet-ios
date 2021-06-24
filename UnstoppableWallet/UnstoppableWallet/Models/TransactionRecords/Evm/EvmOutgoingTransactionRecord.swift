import Foundation
import EthereumKit
import CoinKit

class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    let amount: Decimal
    let to: String
    let token: Coin
    let sentToSelf: Bool

    init(fullTransaction: FullTransaction, amount: Decimal, to: String, token: Coin, sentToSelf: Bool) {
        self.amount = amount
        self.to = to
        self.token = token
        self.sentToSelf = sentToSelf

        super.init(fullTransaction: fullTransaction)
    }

    override var mainCoin: Coin? {
        token
    }

    override var mainAmount: Decimal? {
        amount
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        let coinValue: CoinValue = CoinValue(coin: token, value: amount)
        return .outgoing(to: to, coinValue: coinValue, lockState: nil, conflictingTxHash: nil, sentToSelf: sentToSelf)
    }

}
