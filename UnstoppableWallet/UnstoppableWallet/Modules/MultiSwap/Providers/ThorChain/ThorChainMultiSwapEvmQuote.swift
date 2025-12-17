import EvmKit
import Foundation
import MarketKit

class ThorChainMultiSwapEvmQuote: BaseEvmMultiSwapQuote, IMultiSwapSlippageProvider {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?
    let slippage: Decimal

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, slippage: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.slippage = slippage

        super.init(allowanceState: allowanceState)
    }

    private var slippageModified: Bool {
        slippage != MultiSwapSlippage.default
    }

    override var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil || slippageModified
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        if slippageModified {
            fields.append(.slippage(slippage))
        }

        return fields
    }

    override func cautions() -> [CautionNew] {
        []
    }
}
