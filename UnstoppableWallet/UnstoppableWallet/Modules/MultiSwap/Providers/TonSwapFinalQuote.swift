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
        slippage: Decimal,
        transactionParam: SendTransactionParam,
        fee: Decimal?,
        transactionError: Error?,
    ) {
        self.amountIn = amountIn
        self.transactionParam = transactionParam
        self.fee = fee

        super.init(expectedBuyAmount: expectedAmountOut, slippage: slippage, recipient: recipient, transactionError: transactionError)
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        TonSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        fields.append(contentsOf: TonSendHelper.feeFields(
            fee: fee,
            feeToken: baseToken,
            currency: currency,
            feeTokenRate: baseTokenRate
        ))

        return fields
    }
}
