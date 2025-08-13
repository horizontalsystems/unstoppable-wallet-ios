import Foundation
import MarketKit

class AllBridgeMultiSwapBtcQuote: IMultiSwapQuote {
    let expectedAmountOut: Decimal
    let crosschain: Bool
    let recipient: Address?
    let slippage: Decimal

    init(expectedAmountOut: Decimal, crosschain: Bool, recipient: Address?, slippage: Decimal) {
        self.expectedAmountOut = expectedAmountOut
        self.crosschain = crosschain
        self.recipient = recipient
        self.slippage = slippage
    }

    var amountOut: Decimal {
        expectedAmountOut
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
            fields.append(.recipient(recipient.title))
        }

        if slippage != MultiSwapSlippage.default {
            fields.append(.slippage(slippage))
        }

        return fields
    }

    func cautions() -> [CautionNew] {
        var cautions = [CautionNew]()

        if crosschain {
            cautions.append(CautionNew(title: "swap.allbridge.slip_protection".localized, text: "swap.allbridge.slip_protection.description", type: .warning))
        }

        return cautions
    }
}
