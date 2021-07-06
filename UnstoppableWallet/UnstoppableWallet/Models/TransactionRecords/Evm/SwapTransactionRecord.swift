import Foundation
import EthereumKit
import CoinKit

class SwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    // valueIn stores amountInMax in cases when exact amountIn amount is not known
    let valueIn: CoinValue
    // valueOut stores amountOutMin in cases when exact amountOut amount is not known
    let valueOut: CoinValue?

    init(fullTransaction: FullTransaction, baseCoin: Coin, exchangeAddress: String, tokenIn: Coin, tokenOut: Coin?, amountIn: Decimal, amountOut: Decimal?) {
        self.exchangeAddress = exchangeAddress
        valueIn = CoinValue(coin: tokenIn, value: amountIn)
        if let tokenOut = tokenOut, let amountOut = amountOut {
            valueOut = CoinValue(coin: tokenOut, value: amountOut)
        } else {
            valueOut = nil
        }

        super.init(fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .swap(exchangeAddress: exchangeAddress, valueIn: valueIn, valueOut: valueOut)
    }

}
