import Foundation
import EthereumKit
import CoinKit

class SwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let tokenIn: Coin
    let tokenOut: Coin

    // amountIn stores amountInMax in cases when exact amountIn amount is not known
    let amountIn: Decimal
    // amountOut stores amountOutMin in cases when exact amountOut amount is not known
    let amountOut: Decimal

    let foreignRecipient: Bool

    init(fullTransaction: FullTransaction, exchangeAddress: String, tokenIn: Coin, tokenOut: Coin, amountIn: Decimal, amountOut: Decimal, foreignRecipient: Bool) {
        self.exchangeAddress = exchangeAddress
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.amountIn = amountIn
        self.amountOut = amountOut
        self.foreignRecipient = foreignRecipient

        super.init(fullTransaction: fullTransaction)
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .swap(exchangeAddress: exchangeAddress, inCoinValue: CoinValue(coin: tokenIn, value: amountIn), outCoinValue: CoinValue(coin: tokenOut, value: amountOut))
    }

}
