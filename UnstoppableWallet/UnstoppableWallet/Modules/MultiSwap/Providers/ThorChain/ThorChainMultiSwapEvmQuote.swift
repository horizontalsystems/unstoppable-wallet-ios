import EvmKit
import Foundation
import MarketKit

class ThorChainMultiSwapEvmQuote: BaseEvmMultiSwapQuote, IMultiSwapSlippageProvider {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.swapQuote = swapQuote
        self.recipient = recipient

        super.init(allowanceState: allowanceState)
    }

    override var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil
    }
    
    var slippage: Decimal {
        swapQuote.slipProtectionThreshold.rounded(decimal: 2)
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        fields.append(.slippage(slippage))

        return fields
    }

    override func cautions() -> [CautionNew] {
        // switch MultiSwapSlippage.validate(slippage: slippage) {
        // case .none: ()
        // case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
        // }

        []
    }
}
