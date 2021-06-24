import Foundation
import EthereumKit
import CoinKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let amount: Decimal
    let spender: String
    let token: Coin

    init(fullTransaction: FullTransaction, amount: Decimal, spender: String, token: Coin) {
        self.amount = amount
        self.spender = spender
        self.token = token

        super.init(fullTransaction: fullTransaction)
    }

    override var mainAmount: Decimal? {
        amount
    }

    override var mainCoin: Coin? {
        token
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .approve(spender: spender, coinValue: CoinValue(coin: token, value: amount))
    }

}
