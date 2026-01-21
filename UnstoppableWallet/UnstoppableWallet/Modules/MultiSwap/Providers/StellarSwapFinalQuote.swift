import Foundation
import MarketKit

class StellarSwapFinalQuote: SwapFinalQuote {
    private let amountIn: Decimal
    let transactionData: StellarSendHelper.TransactionData
    private let token: Token
    private let fee: Decimal?

    init(
        amountIn: Decimal,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        transactionData: StellarSendHelper.TransactionData,
        token: Token,
        fee: Decimal?,
        transactionError: Error?
    ) {
        self.amountIn = amountIn
        self.transactionData = transactionData
        self.token = token
        self.fee = fee

        super.init(expectedBuyAmount: expectedAmountOut, slippage: slippage, recipient: recipient, estimatedTime: estimatedTime, transactionError: transactionError)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        StellarSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        fields.append(contentsOf: StellarSendHelper.feeFields(
            fee: fee,
            feeToken: baseToken,
            currency: currency,
            feeTokenRate: baseTokenRate
        ))

        return fields
    }
}
