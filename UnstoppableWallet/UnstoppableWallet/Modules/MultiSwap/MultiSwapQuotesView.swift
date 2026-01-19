import SwiftUI

struct MultiSwapQuotesView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                ListSection {
                    ForEach(viewModel.quotes, id: \.provider.id) { (quote: MultiSwapViewModel.Quote) in
                        Cell(
                            left: {
                                Image(quote.provider.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(6)
                                    .frame(width: .iconSize32, height: .iconSize32)
                            },
                            middle: {
                                MultiText(
                                    subtitle: ComponentText(text: quote.provider.name, colorStyle: .primary),
                                    description: ([quote.provider.type.title] + (quote.provider.aml ? ["swap.aml".localized] : [])).joined(separator: ", "),
                                )
                            },
                            right: {
                                RightTextCheckbox(
                                    subheadSB: quoteCoinValue(quote: quote).map { ComponentText(text: $0, colorStyle: .primary) },
                                    description: quoteCurrencyValue(quote: quote),
                                    description2: priceImpact(quote: quote).map { ComponentText(text: "(\($0.0.rounded(decimal: 2).description)%)", colorStyle: $0.1.colorStyle) },
                                    checked: quote.provider.id == viewModel.currentQuote?.provider.id
                                )
                            },
                            action: {
                                Coordinator.shared.performAfterPurchase(premiumFeature: .swapControl, page: .swap, trigger: .swapQuoteSelect, onPurchase: {
                                    viewModel.userSelectedProviderId = quote.provider.id
                                    isPresented = false
                                })
                            }
                        )
                    }
                }
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 32, trailing: 16))
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

        return AppValue(token: tokenOut, value: quote.quote.expectedBuyAmount).formattedShort()
    }

    private func quoteCurrencyValue(quote: MultiSwapViewModel.Quote) -> String? {
        guard let rateOut = viewModel.rateOut else {
            return nil
        }

        return ValueFormatter.instance.formatShort(currency: viewModel.currency, value: quote.quote.expectedBuyAmount * rateOut)
    }

    private func priceImpact(quote: MultiSwapViewModel.Quote) -> (Decimal, ValueLevel)? {
        guard let amountIn = viewModel.amountIn, let coinPriceIn = viewModel.coinPriceIn, let rateOut = viewModel.rateOut else {
            return nil
        }

        let fiatAmountIn = amountIn * coinPriceIn.value
        let fiatAmountOut = quote.quote.expectedBuyAmount * rateOut

        guard fiatAmountIn != 0, fiatAmountIn > fiatAmountOut else {
            return nil
        }

        let priceImpact = (fiatAmountOut * 100 / fiatAmountIn) - 100

        let level = MultiSwapViewModel.PriceImpactLevel(priceImpact: abs(priceImpact))

        switch level {
        case .negligible:
            return nil
        default:
            return (priceImpact, level.valueLevel)
        }
    }
}
