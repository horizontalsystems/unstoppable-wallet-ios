import SwiftUI

struct BaseCurrencySettingsView: View {
    @ObservedObject var viewModel: BaseCurrencySettingsViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State var confirmationCurrency: Currency?

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ForEach(viewModel.popularCurrencies) { currency in
                    row(currency: currency, showConfirmation: false)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

            VStack {
                ListSectionHeader(text: "settings.base_currency.other".localized)

                ListSection {
                    ForEach(viewModel.otherCurrencies) { currency in
                        row(currency: currency, showConfirmation: true)
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .bottomSheet(item: $confirmationCurrency) { currency in
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("warning_2_24").themeIcon(color: .themeJacob)

                    Text("settings.base_currency.disclaimer".localized).themeHeadline2()

                    Button(action: {
                        confirmationCurrency = nil
                    }) {
                        Image("close_3_24")
                    }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                HighlightedTextView(text: "settings.base_currency.disclaimer.description".localized(AppConfig.appName, viewModel.popularCurrencies.map(\.code).joined(separator: ",")))
                    .padding(.horizontal, .margin16)

                VStack(spacing: .margin12) {
                    Button(action: {
                        viewModel.baseCurrency = currency
                        confirmationCurrency = nil
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("settings.base_currency.disclaimer.set".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))

                    Button(action: {
                        confirmationCurrency = nil
                    }) {
                        Text("button.cancel".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .transparent))
                }
                .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
            }
        }
        .navigationBarTitle("settings.base_currency.title".localized)
    }

    @ViewBuilder private func row(currency: Currency, showConfirmation: Bool) -> some View {
        ClickableRow(action: {
            if viewModel.baseCurrency == currency {
                presentationMode.wrappedValue.dismiss()
            } else if showConfirmation {
                confirmationCurrency = currency
            } else {
                viewModel.baseCurrency = currency
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Image(currency.code)

            VStack(spacing: 1) {
                Text(currency.code).themeBody()
                Text(currency.symbol).themeSubhead2()
            }

            if viewModel.baseCurrency == currency {
                Image.checkIcon
            }
        }
    }
}
