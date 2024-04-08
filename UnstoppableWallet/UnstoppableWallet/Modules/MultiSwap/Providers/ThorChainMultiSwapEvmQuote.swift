import EvmKit
import Foundation
import MarketKit

class ThorChainMultiSwapEvmQuote: BaseEvmMultiSwapQuote {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?
    let slippage: Decimal

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, slippage: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.slippage = slippage

        super.init(allowanceState: allowanceState)
    }

    override var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil || slippage != MultiSwapSlippage.default
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let recipient {
            fields.append(
                MultiSwapMainField(
                    title: "swap.recipient".localized,
                    value: recipient.title,
                    valueLevel: .regular
                )
            )
        }

        if slippage != MultiSwapSlippage.default {
            fields.append(
                MultiSwapMainField(
                    title: "swap.slippage".localized,
                    value: "\(slippage.description)%",
                    valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                )
            )
        }

        return fields
    }

    override func cautions() -> [CautionNew] {
        var cautions = super.cautions()

        switch MultiSwapSlippage.validate(slippage: slippage) {
        case .none: ()
        case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
        }

        return cautions
    }
}
