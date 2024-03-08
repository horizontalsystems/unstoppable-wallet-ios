import EvmKit
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
    var feeData: FeeData? { get }
    var canSwap: Bool { get }
    func cautions(feeToken: Token?) -> [CautionNew]
    func priceSectionFields(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [MultiSwapConfirmField]
    func otherSections(tokenIn: Token, tokenOut: Token, feeToken: Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [[MultiSwapConfirmField]]
}

protocol ISendConfirmationData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    func cautions(feeToken: Token?) -> [CautionNew]
    func sections(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> [[SendConfirmField]]
}

enum SendDataNew {
    case evm(blockchainType: BlockchainType, transactionData: TransactionData)
    case bitcoin(amount: Decimal, recipient: String)
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
    case value(title: String, description: AlertView.InfoDescription?, coinValue: CoinValue?, currencyValue: CurrencyValue?)
    case levelValue(title: String, value: String, level: MultiSwapValueLevel)
    case address(title: String, value: String)
}

enum SendConfirmField {
    case amount(title: String, token: Token, coinValue: String, currencyValue: String?, type: AmountType)
    case value(title: String, description: AlertView.InfoDescription?, coinValue: String?, currencyValue: String?)
    case levelValue(title: String, value: String, level: ValueLevel)
    case address(title: String, value: String, valueTitle: String?, contactAddress: ContactAddress?)

    enum AmountType {
        case incoming
        case outgoing
        case neutral

        var sign: FloatingPointSign {
            switch self {
            case .incoming, .neutral: return .plus
            case .outgoing: return .minus
            }
        }
    }

    enum ValueLevel {
        case regular
        case warning
        case error
    }
}

struct MultiSwapButtonState {
    let title: String
    let disabled: Bool
    let showProgress: Bool
    let preSwapStep: MultiSwapPreSwapStep?

    init(title: String, disabled: Bool = false, showProgress: Bool = false, preSwapStep: MultiSwapPreSwapStep? = nil) {
        self.title = title
        self.disabled = disabled
        self.showProgress = showProgress
        self.preSwapStep = preSwapStep
    }
}
