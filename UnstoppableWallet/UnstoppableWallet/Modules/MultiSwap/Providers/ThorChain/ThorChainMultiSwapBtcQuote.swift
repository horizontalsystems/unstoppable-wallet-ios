import Foundation
import MarketKit

class ThorChainMultiSwapBtcQuote: IMultiSwapQuote, IMultiSwapSlippageProvider {
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

    private var slippageModified: Bool {
        slippage != MultiSwapSlippage.default
    }

    var settingsModified: Bool {
        recipient != nil || slippageModified
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut _: MarketKit.Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
        var fields = [MultiSwapMainField]()

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        fields.append(.slippage(slippage, settingId: MultiSwapMainField.slippageSettingId, modified: slippageModified))

        return fields
    }

    func cautions() -> [CautionNew] {
        []
    }
}
