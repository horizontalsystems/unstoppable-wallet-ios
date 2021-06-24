import Foundation
import EthereumKit
import CoinKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let amount: Decimal
    let from: String
    let token: Coin

    init(fullTransaction: FullTransaction, amount: Decimal, from: String, token: Coin) {
        self.amount = amount
        self.from = from
        self.token = token

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
        return .incoming(from: from, coinValue: coinValue, lockState: nil, conflictingTxHash: nil)
    }

}
