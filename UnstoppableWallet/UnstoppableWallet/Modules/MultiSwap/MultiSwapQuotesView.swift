import SwiftUI

struct MultiSwapQuotesView: View {
    @ObservedObject var viewModel: MultiSwapViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ThemeView(style: .list) {
                ThemeList {
                    Section {
                        ForEach(viewModel.sortedQuotes, id: \.provider.id) { (quote: MultiSwapViewModel.Quote) in
                            VStack(spacing: 0) {
                                if quote.provider.id == viewModel.sortedQuotes.first?.provider.id {
                                    HorizontalDivider()
                                }

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
                                            eyebrow: ComponentText(text: quote.provider.name, colorStyle: .primary),
                                            eyebrowBadge: ComponentBadge(
                                                text: quote.provider.type.title,
                                                change: nil,
                                                mode: .transparent,
                                                colorStyle: quote.provider.type.colorStyle,
                                                onTap: { onTapProviderInfo() }
                                            ),
                                            description: providerDescription(quote: quote)
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
                                        viewModel.userSelectedProviderId = quote.provider.id
                                        isPresented = false
                                    }
                                )

                                HorizontalDivider()
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        headerView()
                    }
                }
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

    @ViewBuilder private func headerView() -> some View {
        ListHeader {
            DropdownButton(text: viewModel.quoteSortType.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "swap.quotes.sort.title".localized,
                        viewItems: MultiSwapViewModel.QuoteSortType.allCases.map {
                            .init(text: $0.title, selected: viewModel.quoteSortType == $0)
                        },
                        onSelect: { index in
                            viewModel.quoteSortType = MultiSwapViewModel.QuoteSortType.allCases[index]
                        },
                        isPresented: isPresented
                    )
                }
            }

            Spacer()
        }
    }

    private func onTapProviderInfo() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            MultiSwapProviderTypeBottomSheet(isPresented: isPresented)
        }
    }

    private func quoteCoinValue(quote: MultiSwapViewModel.Quote) -> String? {
        guard let tokenOut = viewModel.tokenOut else {
            return nil
        }

        return AppValue(token: tokenOut, value: quote.quote.expectedBuyAmount).formattedFull()
    }

    private func quoteCurrencyValue(quote: MultiSwapViewModel.Quote) -> String? {
        guard let rateOut = viewModel.rateOut else {
            return nil
        }

        return ValueFormatter.instance.formatFull(currency: viewModel.currency, value: quote.quote.expectedBuyAmount * rateOut)
    }

    private func providerDescription(quote: MultiSwapViewModel.Quote) -> String? {
        // just estimated time for now
        quote.quote.estimatedTime.map {
            "~ " + Duration.seconds($0).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
        }
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
        case .negligible, .low:
            return nil
        default:
            return (priceImpact, level.valueLevel)
        }
    }
}
