import Foundation
import MarketKit
import TonKit

class TonSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    let transactionParam: SendTransactionParam
    private let fee: Decimal?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        transactionParam: SendTransactionParam,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.amountIn = amountIn
        self.transactionParam = transactionParam
        self.fee = fee

        super.init(
            expectedBuyAmount: expectedAmountOut,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: estimatedTime,
            transactionError: transactionError,
            toAddress: toAddress,
            depositAddress: depositAddress,
            providerSwapId: providerSwapId
        )
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil
    }

    override func executable(tokenIn _: Token) -> ISwapExecutable {
        TonExecutable(transactionParam: transactionParam)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        TonSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        TonSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
