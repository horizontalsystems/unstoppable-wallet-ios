import Foundation
import EthereumKit
import CoinKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: CoinValue

    init(fullTransaction: FullTransaction, baseCoin: Coin, amount: Decimal, from: String, token: Coin) {
        self.from = from
        value = CoinValue(coin: token, value: amount)

        super.init(fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override var mainValue: CoinValue? {
        value
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .incoming(from: from, coinValue: value, lockState: nil, conflictingTxHash: nil)
    }

}
