import Foundation
import MarketKit

class ThorChainMultiSwapBtcQuote: IMultiSwapQuote, IMultiSwapSlippageProvider {
    let swapQuote: ThorChainMultiSwapProvider.SwapQuote
    let recipient: Address?

    init(swapQuote: ThorChainMultiSwapProvider.SwapQuote, recipient: Address?) {
        self.swapQuote = swapQuote
        self.recipient = recipient
    }

    var amountOut: Decimal {
        swapQuote.expectedAmountOut
    }

    var customButtonState: MultiSwapButtonState? {
        nil
    }

    var settingsModified: Bool {
        recipient != nil
    }

    var slippage: Decimal {
        swapQuote.slipProtectionThreshold.rounded(decimal: 2)
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut _: MarketKit.Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
        var fields = [MultiSwapMainField]()

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        fields.append(.slippage(slippage))

        return fields
    }

    func cautions() -> [CautionNew] {
        []
    }
}
