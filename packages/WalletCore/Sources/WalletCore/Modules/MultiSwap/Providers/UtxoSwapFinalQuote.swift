import BitcoinCore
import Foundation
import MarketKit

class UtxoSwapFinalQuote: SwapFinalQuote {
    let sendParameters: SendParameters?
    private let fee: Decimal?

    init(
        expectedBuyAmount: Decimal,
        sendParameters: SendParameters?,
        slippage: Decimal?,
        recipient: String?,
        estimatedTime: TimeInterval? = nil,
        transactionError: Error?,
        fee: Decimal?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.sendParameters = sendParameters
        self.fee = fee

        super.init(
            expectedBuyAmount: expectedBuyAmount,
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
        sendParameters.map { .bitcoin(params: $0) }
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil && sendParameters != nil
    }

    override func executable(tokenIn: Token) -> ISwapExecutable {
        UtxoExecutable(token: tokenIn, sendParameters: sendParameters)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
