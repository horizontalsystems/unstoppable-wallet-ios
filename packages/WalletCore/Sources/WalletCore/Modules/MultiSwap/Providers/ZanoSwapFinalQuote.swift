import Foundation
import MarketKit

class ZanoSwapFinalQuote: SwapFinalQuote {
    let amount: ZanoSendAmount
    let address: String
    let memo: String?
    private let fee: Decimal?

    init(
        expectedAmountOut: Decimal,
        recipient: String?,
        slippage: Decimal?,
        estimatedTime: TimeInterval? = nil,
        amount: ZanoSendAmount,
        address: String,
        memo: String?,
        fee: Decimal?,
        transactionError: Error?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.amount = amount
        self.address = address
        self.memo = memo
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

    override var feeData: FeeData? {
        nil
    }

    override func executable(tokenIn: Token) -> ISwapExecutable {
        ZanoExecutable(token: tokenIn, address: address, amount: amount, memo: memo)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        ZanoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        ZanoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
