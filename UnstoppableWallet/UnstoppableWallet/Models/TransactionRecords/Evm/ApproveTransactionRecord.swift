import Foundation
import EthereumKit
import CoinKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: CoinValue

    init(fullTransaction: FullTransaction, baseCoin: Coin, amount: Decimal, spender: String, token: Coin) {
        self.spender = spender
        value = CoinValue(coin: token, value: amount)

        super.init(fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .approve(spender: spender, coinValue: value)
    }

}
