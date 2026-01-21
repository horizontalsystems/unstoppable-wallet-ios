import BitcoinCore
import Foundation
import MarketKit
import ZcashLightClientKit

class ZcashSwapFinalQuote: SwapFinalQuote {
    let proposal: Proposal?
    private let fee: Decimal?

    init(expectedBuyAmount: Decimal, proposal: Proposal?, slippage: Decimal, recipient: String?, estimatedTime: TimeInterval? = nil, transactionError: Error?, fee: Decimal?) {
        self.proposal = proposal
        self.fee = fee

        super.init(expectedBuyAmount: expectedBuyAmount, slippage: slippage, recipient: recipient, estimatedTime: estimatedTime, transactionError: transactionError)
    }

    override var feeData: FeeData? {
        fee.map { .zcash(fee: $0) }
    }

    override var canSwap: Bool {
        super.canSwap && proposal != nil && fee != nil
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
