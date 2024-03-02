import Foundation
import MarketKit

protocol IMultiSwapQuote {
    var amountOut: Decimal { get }
    var customButtonState: MultiSwapButtonState? { get }
    var settingsModified: Bool { get }
    func fields(tokenIn: Token, tokenOut: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField]
    func cautions() -> [CautionNew]
}

protocol IMultiSwapConfirmationQuote {
    var amountOut: Decimal { get }
    var feeQuote: MultiSwapFeeQuote? { get }
    var canSwap: Bool { get }
    func cautions(feeToken: Token) -> [CautionNew]
    func priceSectionFields(tokenIn: Token, tokenOut: Token, feeToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [MultiSwapConfirmField]
    func otherSections(tokenIn: Token, tokenOut: Token, feeToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[MultiSwapConfirmField]]
}

struct MultiSwapTokenAmount {
    let token: Token
    let amount: Decimal
}

struct MultiSwapMainField: Identifiable {
    let title: String
    let description: AlertView.InfoDescription?
    let value: String
    let valueLevel: MultiSwapValueLevel
    let settingId: String?
    let modified: Bool

    init(title: String, description: AlertView.InfoDescription? = nil, value: String, valueLevel: MultiSwapValueLevel = .regular, settingId: String? = nil, modified: Bool = false) {
        self.title = title
        self.description = description
        self.value = value
        self.valueLevel = valueLevel
        self.settingId = settingId
        self.modified = modified
    }

    var id: String {
        title
    }
}

enum MultiSwapValueLevel {
    case regular
    case notAvailable
    case warning
    case error
}

enum MultiSwapConfirmField {
    case value(title: String, description: AlertView.InfoDescription?, coinValue: CoinValue, currencyValue: CurrencyValue?)
    case levelValue(title: String, value: String, level: MultiSwapValueLevel)
    case address(title: String, value: String)
}

struct MultiSwapButtonState {
    let title: String
    let disabled: Bool
    let showProgress: Bool
    let preSwapStepId: String?

    init(title: String, disabled: Bool = false, showProgress: Bool = false, preSwapStepId: String? = nil) {
        self.title = title
        self.disabled = disabled
        self.showProgress = showProgress
        self.preSwapStepId = preSwapStepId
    }
}
