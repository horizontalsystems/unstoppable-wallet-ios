import Foundation
import EthereumKit
import MarketKit

class SwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let valueIn: TransactionValue    // valueIn stores amountInMax in cases when exact amountIn amount is not known
    let valueOut: TransactionValue?  // valueOut stores amountOutMin in cases when exact amountOut amount is not known
    let foreignRecipient: Bool

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: PlatformCoin, exchangeAddress: String, valueIn: TransactionValue, valueOut: TransactionValue?, foreignRecipient: Bool) {
        self.exchangeAddress = exchangeAddress
        self.valueIn = valueIn
        self.valueOut = valueOut

        self.foreignRecipient = foreignRecipient

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

}
