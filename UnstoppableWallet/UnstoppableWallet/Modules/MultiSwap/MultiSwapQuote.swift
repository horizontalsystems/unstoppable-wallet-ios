import Foundation
import MarketKit

struct MultiSwapQuote {
    let amountOut: Decimal
    let fee: TokenAmount?
    let fields: [Field]

    struct TokenAmount {
        let token: Token
        let amount: Decimal
    }

    struct Field: Identifiable {
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
}
