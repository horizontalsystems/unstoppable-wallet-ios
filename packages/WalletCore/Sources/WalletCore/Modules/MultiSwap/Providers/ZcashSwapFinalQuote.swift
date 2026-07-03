import BitcoinCore
import Foundation
import MarketKit
import ZcashLightClientKit

class ZcashSwapFinalQuote: SwapFinalQuote {
    let proposal: Proposal?
    private let fee: Decimal?

    init(
        expectedBuyAmount: Decimal,
        proposal: Proposal?,
        slippage: Decimal?,
        recipient: String?,
        estimatedTime: TimeInterval? = nil,
        transactionError: Error?,
        fee: Decimal?,
        toAddress: String,
        depositAddress: String? = nil,
        providerSwapId: String? = nil
    ) {
        self.proposal = proposal
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
        fee.map { .zcash(fee: $0) }
    }

    override var canSwap: Bool {
        super.canSwap && proposal != nil && fee != nil
    }

    override func executable(tokenIn: Token) -> ISwapExecutable {
        ZcashExecutable(token: tokenIn, proposal: proposal)
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        UtxoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }

    override func feeFields(baseToken: Token, currency: Currency, baseTokenRate: Decimal?) -> [SendField] {
        UtxoSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)
    }
}
