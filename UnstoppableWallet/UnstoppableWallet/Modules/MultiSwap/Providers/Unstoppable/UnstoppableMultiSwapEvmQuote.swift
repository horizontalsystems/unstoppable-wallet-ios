import EvmKit
import Foundation
import MarketKit

class UnstoppableMultiSwapEvmQuote: BaseEvmMultiSwapQuote {
    let expectedAmountOut: Decimal
    let recipient: Address?
    let slippage: Decimal

    init(expectedAmountOut: Decimal, recipient: Address?, slippage: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.slippage = slippage

        super.init(allowanceState: allowanceState)
    }

    private var slippageModified: Bool {
        slippage != MultiSwapSlippage.default
    }

    override var amountOut: Decimal {
        expectedAmountOut
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil || slippageModified
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = [MultiSwapMainField]()

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        fields.append(.slippage(slippage, settingId: MultiSwapMainField.slippageSettingId, modified: slippageModified))

        fields.append(contentsOf: super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate))
        return fields
    }
}
