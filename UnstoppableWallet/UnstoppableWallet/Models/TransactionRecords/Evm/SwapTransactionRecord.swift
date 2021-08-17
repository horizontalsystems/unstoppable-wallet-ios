import Foundation
import EthereumKit
import CoinKit

class SwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let valueIn: CoinValue    // valueIn stores amountInMax in cases when exact amountIn amount is not known
    let valueOut: CoinValue?  // valueOut stores amountOutMin in cases when exact amountOut amount is not known
    let foreignRecipient: Bool

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: Coin, exchangeAddress: String, tokenIn: Coin, tokenOut: Coin?, amountIn: Decimal, amountOut: Decimal?, foreignRecipient: Bool) {
        self.exchangeAddress = exchangeAddress
        valueIn = CoinValue(coin: tokenIn, value: amountIn)
        if let tokenOut = tokenOut, let amountOut = amountOut {
            valueOut = CoinValue(coin: tokenOut, value: amountOut)
        } else {
            valueOut = nil
        }
        
        self.foreignRecipient = foreignRecipient

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

}
