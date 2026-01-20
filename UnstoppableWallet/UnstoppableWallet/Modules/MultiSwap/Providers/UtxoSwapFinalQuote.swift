import BitcoinCore
import Foundation
import MarketKit

class UtxoSwapFinalQuote: SwapFinalQuote {
    let sendParameters: SendParameters?
    private let fee: Decimal?

    init(
        expectedBuyAmount: Decimal,
        sendParameters: SendParameters?,
        slippage: Decimal,
        recipient: String?,
        transactionError: Error?,
        fee: Decimal?,
    ) {
        self.sendParameters = sendParameters
        self.fee = fee

        super.init(expectedBuyAmount: expectedBuyAmount, slippage: slippage, recipient: recipient, transactionError: transactionError)
    }

    override var feeData: FeeData? {
        sendParameters.map { .bitcoin(params: $0) }
    }

    override var canSwap: Bool {
        super.canSwap && fee != nil && sendParameters != nil
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func fields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        fields.append(contentsOf: UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
