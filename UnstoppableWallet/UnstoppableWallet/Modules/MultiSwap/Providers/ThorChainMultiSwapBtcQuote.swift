import Foundation
import MarketKit

class ThorChainMultiSwapBtcQuote: IMultiSwapQuote {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?
    let slippage: Decimal

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?, slippage: Decimal) {
        self.swapQuote = swapQuote
        self.recipient = recipient
        self.slippage = slippage
    }

    var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    var customButtonState: MultiSwapButtonState? {
        nil
    }

    var settingsModified: Bool {
        recipient != nil || slippage != MultiSwapSlippage.default
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut _: MarketKit.Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
        var fields = [MultiSwapMainField]()

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

    func cautions() -> [CautionNew] {
        var cautions = [CautionNew]()

        switch MultiSwapSlippage.validate(slippage: slippage) {
        case .none: ()
        case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
        }

        return cautions
    }
}
