import Foundation
import MarketKit

class AllBridgeMultiSwapStellarQuote: IMultiSwapQuote {
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

        if !crosschain {
            fields.append(.slippage(slippage, settingId: MultiSwapMainField.slippageSettingId, modified: slippageModified))
        }

        return fields
    }

    func cautions() -> [CautionNew] {
        []
    }
}
