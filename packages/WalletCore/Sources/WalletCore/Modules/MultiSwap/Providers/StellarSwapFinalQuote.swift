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
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.amountIn = amountIn
        self.transactionData = transactionData
        self.token = token
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

    override func executable(tokenIn: Token) -> ISwapExecutable {
        StellarExecutable(token: tokenIn, transactionData: transactionData)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        StellarSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        StellarSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
