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
                                    middle: {
                                        TextCheckbox(
                                            subheadSB: quoteCoinValue(quote: quote).map { ComponentText(text: $0, colorStyle: .primary) },
                                            description: quoteCurrencyValue(quote: quote),
                                            description2: priceImpact(quote: quote).map { ComponentText(text: "(\($0.0.rounded(decimal: 2).description)%)", colorStyle: $0.1.colorStyle) },
                                            checked: quote.provider.id == viewModel.currentQuote?.provider.id,
                                            alignment: .leading
                                        )
                                    },
                                    right: {
                                        providerDescriptionView(quote: quote)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
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

    @ViewBuilder private func providerDescriptionView(quote: MultiSwapViewModel.Quote) -> some View {
        let type = quote.provider.type

        VStack(alignment: .trailing, spacing: 1) {
            Button(action: onTapProviderInfo) {
                Self.view(type: type, style: .subheadSB, iconFirst: false)
            }
            .buttonStyle(.plain)
            if let timeState = quote.timeState {
                Self.view(estimatedTime: timeState.time, colorStyle: timeState.colorStyle, style: .subheadSB, showIcon: false)
            }
        }
        .fixedSize()
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

extension MultiSwapQuotesView {
    enum Style {
        case subheadSB
        case captionSB

        var hMargin: CGFloat { self == .subheadSB ? 8 : 4 }
        var iconSize: CGFloat { self == .subheadSB ? .iconSize20 : .iconSize16 }
        var textStyle: TextStyle { self == .subheadSB ? .subheadSB : .captionSB }
    }

    @ViewBuilder static func view(estimatedTime: TimeInterval, colorStyle: ColorStyle = .yellow, style: Style = .subheadSB, iconFirst: Bool = false, showIcon: Bool = true) -> some View {
        let timeString = Duration.seconds(estimatedTime).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))

        HStack(spacing: style.hMargin) {
            if iconFirst {
                if showIcon {
                    ThemeImage("clock_filled", size: style.iconSize, colorStyle: colorStyle)
                }
                ThemeText(timeString, style: style.textStyle, colorStyle: colorStyle)
            } else {
                ThemeText(timeString, style: style.textStyle, colorStyle: colorStyle)
                if showIcon {
                    ThemeImage("clock_filled", size: style.iconSize, colorStyle: colorStyle)
                }
            }
        }
    }

    @ViewBuilder static func view(type: SwapProviderType, style: Style = .subheadSB, iconFirst: Bool = false) -> some View {
        HStack(spacing: style.hMargin) {
            if iconFirst {
                ThemeImage(type.icon, size: style.iconSize, colorStyle: type.сolorStyle)
                ThemeText(type.title, style: style.textStyle, colorStyle: type.сolorStyle)
            } else {
                ThemeText(type.title, style: style.textStyle, colorStyle: type.сolorStyle)
                ThemeImage(type.icon, size: style.iconSize, colorStyle: type.сolorStyle)
            }
        }
    }
}
