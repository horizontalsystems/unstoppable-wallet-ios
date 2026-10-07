import Foundation
import MarketKit

class NearSwapFinalQuote: SwapFinalQuote {
    private let token: Token
    private let address: String
    private let amount: Decimal
    private let estimate: NearSendEstimate?
    private let fee: Decimal?
    private let previousTransactionPending: Bool

    init(
        token: Token,
        address: String,
        amount: Decimal,
        estimate: NearSendEstimate?,
        fee: Decimal?,
        previousTransactionPending: Bool,
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.token = token
        self.address = address
        self.amount = amount
        self.estimate = estimate
        self.fee = fee
        self.previousTransactionPending = previousTransactionPending

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

    override func buildExecutable(tokenIn: Token) -> ISwapExecutable {
        NearExecutable(token: tokenIn, address: address, amount: amount, estimate: estimate)
    }

    override func cautions(baseToken: Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        // the deposit leg goes through the same send service as the send screen on Android
        if previousTransactionPending {
            cautions.append(NearSendHelper.pendingCaution())
        }

        return cautions
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        NearSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        NearSendHelper.feeFields(fee: fee, storageDeposit: estimate?.storageDeposit, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
