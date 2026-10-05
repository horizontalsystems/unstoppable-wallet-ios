import MarketKit
import SwiftUI

/// Token amount below a swap's Pay/Get header, including an explicit on-chain limit.
struct SwapAmountField: SendFieldContent {
    let token: Token
    let appValue: AppValue
    let currencyValue: CurrencyValue?
    let incoming: Bool
    let suffix: String?

    var amountText: String {
        [appValue.formattedFull(showCode: false), suffix].compactMap { $0 }.joined(separator: " ")
    }

    @MainActor func listRow() -> some View {
        Cell(
            left: {
                CoinIconView(token: token)
            },
            middle: {
                MultiText(eyebrow: ComponentText(text: amountText, colorStyle: incoming ? .green : .primary))
            },
            right: {
                RightMultiText(subtitle: currencyValue?.formattedFull)
            }
        )
    }
}
