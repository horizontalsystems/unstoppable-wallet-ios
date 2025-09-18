import EvmKit
import Foundation
import MarketKit
import OneInchKit

class OneInchMultiSwapQuote: BaseEvmMultiSwapQuote {
    let quote: OneInchKit.Quote
    let recipient: Address?
    let slippage: Decimal

    init(quote: OneInchKit.Quote, recipient: Address?, slippage: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.quote = quote
        self.recipient = recipient
        self.slippage = slippage

        super.init(allowanceState: allowanceState)
    }

    override var amountOut: Decimal {
        quote.amountOut ?? 0
    }

    private var slippageModified: Bool {
        slippage != MultiSwapSlippage.default
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil || slippageModified
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        fields.append(.slippage(slippage, settingId: MultiSwapMainField.slippageSettingId, modified: slippageModified))

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
