import SwiftUI

struct BaseCurrencySettingsView: View {
    @ObservedObject var viewModel: BaseCurrencySettingsViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ForEach(viewModel.popularCurrencies, id: \.self) { currency in
                    row(currency: currency, showConfirmation: false)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))

            VStack {
                ListSectionHeader(text: "settings.base_currency.other".localized)

                ListSection {
                    ForEach(viewModel.otherCurrencies, id: \.self) { currency in
                        row(currency: currency, showConfirmation: true)
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationBarTitle("settings.base_currency.title".localized)
    }

    @ViewBuilder private func row(currency: Currency, showConfirmation: Bool) -> some View {
        ClickableRow(action: {
            if viewModel.baseCurrency == currency {
                presentationMode.wrappedValue.dismiss()
            } else if showConfirmation {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    confirmView(currency: currency, isPresented: isPresented)
                }
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

    @ViewBuilder private func confirmView(currency: Currency, isPresented: Binding<Bool>) -> some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.warning, title: "settings.base_currency.disclaimer".localized),
                .warning(text: "settings.base_currency.disclaimer.description".localized(AppConfig.appName, viewModel.popularCurrencies.map(\.code).joined(separator: ", "))),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "settings.base_currency.disclaimer.set".localized) {
                        viewModel.baseCurrency = currency
                        isPresented.wrappedValue = false
                        presentationMode.wrappedValue.dismiss()
                    },
                    .init(style: .transparent, title: "button.cancel".localized) {
                        isPresented.wrappedValue = false
                    },
                ])),
            ],
        )
    }
}
