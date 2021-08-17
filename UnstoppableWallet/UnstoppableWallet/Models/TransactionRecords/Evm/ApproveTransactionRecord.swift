import Foundation
import EthereumKit
import CoinKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: CoinValue

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: Coin, amount: Decimal, spender: String, token: Coin) {
        self.spender = spender
        value = CoinValue(coin: token, value: amount)

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

}
