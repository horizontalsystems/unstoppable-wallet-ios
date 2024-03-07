import SwiftUI

struct MultiSwapQuotesView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationView {
            ScrollableThemeView {
                VStack {
                    ForEach(viewModel.quotes, id: \.provider.id) { (quote: MultiSwapViewModel.Quote) in
                        ListSection(selected: quote.provider.id == viewModel.currentQuote?.provider.id) {
                            ClickableRow(action: {
                                viewModel.userSelectedProviderId = quote.provider.id
                                isPresented = false
                            }) {
                                Image(quote.provider.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: .iconSize32, height: .iconSize32)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(quote.provider.name).textSubhead2(color: .themeLeah)

                                    if quote.provider.id == viewModel.bestQuote?.provider.id {
                                        Text("swap.quotes.best_price".localized).textSubhead2(color: .themeRemus)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 1) {
                                    if let value = quoteCoinValue(quote: quote) {
                                        Text(value)
                                            .textSubhead2(color: .themeLeah)
                                            .multilineTextAlignment(.trailing)
                                    } else {
                                        Text("n/a".localized).textSubhead2(color: .themeGray50)
                                    }

                                    if let value = quoteCurrencyValue(quote: quote) {
                                        Text(value)
                                            .textCaption(color: .themeGray)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                        .themeListStyle(.bordered)
                        .padding(.bottom, .margin8)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("swap.quotes.providers".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    isPresented = false
                }
            }
        }
    }

    private func quoteCoinValue(quote: MultiSwapViewModel.Quote) -> String? {
        guard let tokenOut = viewModel.tokenOut else {
            return nil
        }

        return ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: tokenOut), value: quote.quote.amountOut))
    }

    private func quoteCurrencyValue(quote: MultiSwapViewModel.Quote) -> String? {
        guard let rateOut = viewModel.rateOut else {
            return nil
        }

        return ValueFormatter.instance.formatShort(currency: viewModel.currency, value: quote.quote.amountOut * rateOut)
    }
}
