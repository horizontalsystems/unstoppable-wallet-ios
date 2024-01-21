import Foundation
import MarketKit

protocol IMultiSwapQuote {
    var amountOut: Decimal { get }
    var fee: CoinValue? { get }
    var mainFields: [MultiSwapMainField] { get }
}

struct MultiSwapTokenAmount {
    let token: Token
    let amount: Decimal
}

struct MultiSwapMainField: Identifiable {
    let title: String
    let memo: Memo?
    let value: String
    let valueLevel: ValueLevel
    let settingId: String?
    let modified: Bool

    init(title: String, memo: Memo? = nil, value: String, valueLevel: ValueLevel = .regular, settingId: String? = nil, modified: Bool = false) {
        self.title = title
        self.memo = memo
        self.value = value
        self.valueLevel = valueLevel
        self.settingId = settingId
        self.modified = modified
    }

    var id: String {
        title
    }

    struct Memo {
        let title: String
        let text: String
    }

    enum ValueLevel {
        case regular
        case warning
        case error
    }
}
