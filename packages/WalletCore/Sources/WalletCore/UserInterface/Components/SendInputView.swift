import MarketKit
import SwiftUI

struct SendInputView<FocusField: Hashable>: View {
    let token: Token?
    @Binding var amountString: String
    @Binding var fiatAmountString: String
    let coinPrice: CoinPrice?
    let currency: Currency
    var focusedField: FocusState<FocusField?>.Binding
    let amountField: FocusField
    let fiatField: FocusField
    var onSelectToken: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            TokenSelectorButton(token: token, action: onSelectToken)

            VStack(alignment: .trailing, spacing: 0) {
                TextField("", text: $amountString, prompt: Text("0").foregroundColor(.themeGray))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.themeLeah)
                    .font(.themeHeadline1)
                    .tint(.themeInputFieldTintColor)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: amountField)
                    .frame(height: 33)

                if token != nil {
                    if let coinPrice {
                        HStack(spacing: 0) {
                            ThemeText(currency.symbol, style: .body, colorStyle: fiatAmountString.isEmpty ? .andy : .secondary)

                            TextField("", text: $fiatAmountString, prompt: Text("0").foregroundColor(.themeAndy))
                                .fixedSize(horizontal: true, vertical: false)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.themeGray)
                                .font(.themeBody)
                                .tint(.themeInputFieldTintColor)
                                .keyboardType(.decimalPad)
                                .focused(focusedField, equals: fiatField)
                                .frame(height: 22)
                                .disabled(coinPrice.expired)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        ThemeText("n/a".localized, style: .body, colorStyle: .andy)
                            .frame(height: 22)
                    }
                } else {
                    ThemeText("\(currency.symbol)0", style: .body, colorStyle: .andy)
                        .frame(height: 22)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
