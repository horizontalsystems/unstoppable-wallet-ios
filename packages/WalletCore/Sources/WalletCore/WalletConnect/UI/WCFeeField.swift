import MarketKit
import SwiftUI

// Android WCSendEthScreen FeeCell: coin amount and fiat shown together. While the gas estimate is still
// pending (loading) the value is replaced by a spinner, so the request sheet can open full with the rows
// already visible instead of blocking the whole screen on a loader.
struct WCFeeField: SendFieldContent {
    let title: CustomStringConvertible
    let amountData: AmountData?
    let loading: Bool

    @ViewBuilder @MainActor func listRow() -> some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: title).styled(title)
            },
            right: {
                if loading {
                    // reserve the loaded two-line (coin + fiat) height so the row does not grow when the fee lands
                    RightMultiText(eyebrow: ComponentText(text: " ", colorStyle: .primary), subtitle: " ")
                        .hidden()
                        .overlay(ProgressView().progressViewStyle(.circular))
                } else {
                    let formatted = amountData?.appValue.formattedFull()
                    // always render the fiat line (dash placeholder when the rate is missing) so its
                    // appearance later does not add a second line and jump the whole sheet's height
                    RightMultiText(
                        eyebrow: ComponentText(text: formatted ?? "n/a".localized, colorStyle: formatted != nil ? .primary : .secondary),
                        subtitle: amountData?.currencyValue?.formattedFull ?? "---"
                    )
                }
            }
        )
    }
}
