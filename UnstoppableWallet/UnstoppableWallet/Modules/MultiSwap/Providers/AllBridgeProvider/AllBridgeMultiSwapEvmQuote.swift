import EvmKit
import Foundation
import MarketKit

class AllBridgeMultiSwapEvmQuote: BaseEvmMultiSwapQuote {
    let expectedAmountOut: Decimal
    let crosschain: Bool
    let recipient: Address?
    let slippage: Decimal

    init(expectedAmountOut: Decimal, crosschain: Bool, recipient: Address?, slippage: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.expectedAmountOut = expectedAmountOut
        self.crosschain = crosschain
        self.recipient = recipient
        self.slippage = slippage

        super.init(allowanceState: allowanceState)
    }

    override var amountOut: Decimal {
        expectedAmountOut
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil || slippage != MultiSwapSlippage.default
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        if !crosschain, slippage != MultiSwapSlippage.default {
            fields.append(.slippage(slippage))
        }

        return fields
    }

    override func cautions() -> [CautionNew] {
        var cautions = super.cautions()

        if crosschain {
            cautions.append(CautionNew(title: "swap.allbridge.slip_protection".localized, text: "swap.allbridge.slip_protection.description", type: .warning))
        }

        return cautions
    }
}
