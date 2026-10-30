import MarketKit
import SwiftUI

struct MarketAdvancedSearchView: View {
    @StateObject private var viewModel = MarketAdvancedSearchViewModel()
    @Binding var isParentPresented: Bool

    @State private var resultsPresented = false

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        ListSection {
                            topRow()
                            volumeRow()
                            blockchainsRow()
                        }

                        VStack(spacing: 0) {
                            PremiumListSectionHeader()
                            ListSection {
                                categoriesRow()
                            }
                            .modifier(ColoredBorder())
                        }

                        VStack(spacing: 0) {
                            ListSection {
                                priceChangeRow()
                                pricePeriodRow()
                                signalRow()
                                priceCloseToRow()
                            }
                            .modifier(ColoredBorder())
                        }

                        VStack(spacing: 0) {
                            ListSection {
                                premiumRow(title: "market.advanced_search.outperformed_btc".localized, isOn: $viewModel.outperformedBtc, statPremiumKey: .outperformedBtc)
                                premiumRow(title: "market.advanced_search.outperformed_eth".localized, isOn: $viewModel.outperformedEth, statPremiumKey: .outperformedEth)
                                premiumRow(title: "market.advanced_search.outperformed_bnb".localized, isOn: $viewModel.outperformedBnb, statPremiumKey: .outperformedBnb)
                                premiumRow(title: "market.advanced_search.outperformed_sp500".localized, isOn: $viewModel.outperformedSp500, statPremiumKey: .outperformedSp500)
                                premiumRow(title: "market.advanced_search.outperformed_gold".localized, isOn: $viewModel.outperformedGold, statPremiumKey: .outperformedGold)
                            }
                            .modifier(ColoredBorder())
                        }

                        VStack(spacing: 0) {
                            ListSection {
                                premiumRow(
                                    title: "market.advanced_search.good_cex_volume".localized,
                                    subtitle: "market.advanced_search.overall_score_is_good_or_excellent".localized,
                                    isOn: $viewModel.goodCexVolume,
                                    statPremiumKey: .goodCexVolume
                                )
                                premiumRow(
                                    title: "market.advanced_search.good_dex_volume".localized,
                                    subtitle: "market.advanced_search.overall_score_is_good_or_excellent".localized,
                                    isOn: $viewModel.goodDexVolume,
                                    statPremiumKey: .goodDexVolume
                                )
                                premiumRow(
                                    title: "market.advanced_search.good_distribution".localized,
                                    subtitle: "market.advanced_search.overall_score_is_good_or_excellent".localized,
                                    isOn: $viewModel.goodDistribution,
                                    statPremiumKey: .goodDistribution
                                )
                                premiumRow(title: "market.advanced_search.listed_on_top_exchanges".localized, isOn: $viewModel.listedOnTopExchanges, statPremiumKey: .listedOnTopExchanges)
                            }
                            .modifier(ColoredBorder())
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                switch viewModel.state {
                case .loading:
                    ThemeButton(text: "market.advanced_search.show_results".localized, spinner: true) {}
                        .disabled(true)
                case let .loaded(marketInfos):
                    let resultsText = marketInfos.isEmpty ? "market.advanced_search.empty_results".localized : "\("market.advanced_search.show_results".localized): \(marketInfos.count)"

                    ThemeButton(text: resultsText) {
                        resultsPresented = true
                    }
                    .disabled(marketInfos.isEmpty)
                case .failed:
                    ThemeButton(text: "market.advanced_search.retry".localized, style: .secondary) {
                        viewModel.syncMarketInfos()
                    }
                }
            }
        }
        .navigationTitle("market.advanced_search.title".localized)
        .navigationDestination(isPresented: $resultsPresented) {
            if case let .loaded(marketInfos) = viewModel.state {
                MarketAdvancedSearchResultsView(marketInfos: marketInfos, timePeriod: viewModel.priceChangePeriod, isParentPresented: $isParentPresented)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    viewModel.reset()
                }) {
                    Image("reset")
                }
                .disabled(!viewModel.canReset)
            }
        }
    }

    @ViewBuilder private func topRow() -> some View {
        dropdownRow(title: "market.advanced_search.choose_set".localized, value: viewModel.top.title) {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(viewModel.tops) { top in
                        Cell(
                            middle: { MultiText(title: top.title, subtitle: top.description) },
                            right: {
                                if viewModel.top == top {
                                    Image.checkIcon
                                }
                            },
                            action: {
                                viewModel.top = top
                                isPresented.wrappedValue = false
                            }
                        )
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "circle_coin_24", title: "market.advanced_search.choose_set", isPresented: isPresented))
            }
        }
    }

    @ViewBuilder private func volumeRow() -> some View {
        dropdownRow(title: "market.advanced_search.volume".localized, value: viewModel.volume.title, colorStyle: colorStyle(valueFilter: viewModel.volume)) {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(viewModel.valueFilters) { filter in
                        optionRow(title: filter.title, colorStyle: colorStyle(valueFilter: filter), selected: viewModel.volume == filter) {
                            viewModel.volume = filter
                            isPresented.wrappedValue = false
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "chart_2_24", title: "market.advanced_search.volume", isPresented: isPresented))
            }
        }
    }

    @ViewBuilder private func categoriesRow() -> some View {
        dropdownRow(title: "market.advanced_search.categories".localized, value: viewModel.categories.title, colorStyle: colorStyle(categoriesFilter: viewModel.categories)) {
            Coordinator.shared.presentAfterPurchase(premiumFeature: .advancedSearch, page: .advancedSearch, trigger: .sectors) { isPresented in
                MarketAdvancedSearchCategoriesView(viewModel: viewModel, isPresented: isPresented)
            }
        }
    }

    @ViewBuilder private func premiumRow(title: String, subtitle: String? = nil, isOn: Binding<Bool>, statPremiumKey: StatPremiumTrigger) -> some View {
        let enabled = viewModel.advancedSearchEnabled

        Cell(
            middle: { MultiText(title: title, subtitle: subtitle) },
            right: { ThemeToggle(isOn: isOn).disabled(!enabled) },
            action: enabled ? nil : {
                Coordinator.shared.presentPurchase(premiumFeature: .advancedSearch, page: .advancedSearch, trigger: statPremiumKey)
            }
        )
    }

    @ViewBuilder private func blockchainsRow() -> some View {
        let value = blockchainsValue

        dropdownRow(title: "market.advanced_search.blockchains".localized, value: value.text, colorStyle: value.colorStyle) {
            Coordinator.shared.present { isPresented in
                MarketAdvancedSearchBlockchainsView(viewModel: viewModel, isPresented: isPresented)
            }
        }
    }

    private var blockchainsValue: (text: String, colorStyle: ColorStyle) {
        if viewModel.blockchains.isEmpty {
            return ("selector.any".localized, .secondary)
        } else if viewModel.blockchains.count == 1, let blockchain = viewModel.blockchains.first {
            return (blockchain.name, .primary)
        } else {
            return ("\(viewModel.blockchains.count)", .primary)
        }
    }

    @ViewBuilder private func signalRow() -> some View {
        dropdownRow(
            title: "market.advanced_search.signal".localized,
            value: viewModel.signal?.title ?? "selector.any".localized,
            colorStyle: viewModel.signal == nil ? .secondary : .primary
        ) {
            Coordinator.shared.performAfterPurchase(premiumFeature: .advancedSearch, page: .advancedSearch, trigger: .tradingSignal) {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    ListSection {
                        optionRow(title: "selector.any".localized, colorStyle: .secondary, selected: viewModel.signal == nil) {
                            viewModel.signal = nil
                            isPresented.wrappedValue = false
                        }

                        ForEach(viewModel.signals) { signal in
                            optionRow(title: signal.title, selected: viewModel.signal == signal) {
                                viewModel.signal = signal
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                    .themeListStyle(.bordered)
                    .modifier(AdvancedSearchHeaderModifier(imageName: "bell_ring_24", title: "market.advanced_search.signal", isPresented: isPresented))
                }
            }
        }
    }

    @ViewBuilder private func priceChangeRow() -> some View {
        dropdownRow(title: "market.advanced_search.price_change".localized, value: viewModel.priceChange.title, colorStyle: colorStyle(priceChangeFilter: viewModel.priceChange)) {
            Coordinator.shared.performAfterPurchase(premiumFeature: .advancedSearch, page: .advancedSearch, trigger: .priceChange) {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    ListSection {
                        ForEach(MarketAdvancedSearchViewModel.PriceChangeFilter.allCases) { filter in
                            optionRow(title: filter.title, colorStyle: colorStyle(priceChangeFilter: filter), selected: viewModel.priceChange == filter) {
                                viewModel.priceChange = filter
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                    .themeListStyle(.bordered)
                    .modifier(AdvancedSearchHeaderModifier(imageName: "markets_24", title: "market.advanced_search.price_change", isPresented: isPresented))
                }
            }
        }
    }

    @ViewBuilder private func pricePeriodRow() -> some View {
        dropdownRow(title: "market.advanced_search.price_period".localized, value: viewModel.priceChangePeriod.title) {
            Coordinator.shared.performAfterPurchase(premiumFeature: .advancedSearch, page: .advancedSearch, trigger: .pricePeriod) {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    ListSection {
                        ForEach(viewModel.priceChangePeriods) { period in
                            optionRow(title: period.title, selected: viewModel.priceChangePeriod == period) {
                                viewModel.priceChangePeriod = period
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                    .themeListStyle(.bordered)
                    .modifier(AdvancedSearchHeaderModifier(imageName: "circle_clock_24", title: "market.advanced_search.price_period", isPresented: isPresented))
                }
            }
        }
    }

    @ViewBuilder private func priceCloseToRow() -> some View {
        dropdownRow(title: "market.advanced_search.price_close_to".localized, value: viewModel.priceCloseTo.title, colorStyle: colorStyle(closeToFilter: viewModel.priceCloseTo)) {
            Coordinator.shared.performAfterPurchase(premiumFeature: .advancedSearch, page: .advancedSearch, trigger: .priceCloseTo) {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    ListSection {
                        ForEach(MarketAdvancedSearchViewModel.PriceCloseToFilter.allCases) { closeTo in
                            optionRow(title: closeTo.title, colorStyle: colorStyle(closeToFilter: closeTo), selected: viewModel.priceCloseTo == closeTo) {
                                viewModel.priceCloseTo = closeTo
                                isPresented.wrappedValue = false
                            }
                        }
                    }
                    .themeListStyle(.bordered)
                    .modifier(AdvancedSearchHeaderModifier(imageName: "arrow_swap_24", title: "market.advanced_search.price_close_to", isPresented: isPresented))
                }
            }
        }
    }

    @ViewBuilder private func dropdownRow(title: String, value: String, colorStyle: ColorStyle = .primary, action: @escaping () -> Void) -> some View {
        Cell(
            middle: { ThemeText(title, style: .headline2) },
            right: {
                ThemeText(value, style: .subheadSB, colorStyle: colorStyle)
                    .arrow(style: .dropdown)
            },
            action: action
        )
    }

    @ViewBuilder private func optionRow(title: String, colorStyle: ColorStyle = .primary, selected: Bool, action: @escaping () -> Void) -> some View {
        Cell(
            middle: { ThemeText(title, style: .headline2, colorStyle: colorStyle) },
            right: {
                if selected {
                    Image.checkIcon
                }
            },
            action: action
        )
    }

    private func colorStyle(valueFilter: MarketAdvancedSearchViewModel.ValueFilter) -> ColorStyle {
        switch valueFilter {
        case .none: return .secondary
        default: return .primary
        }
    }

    private func colorStyle(categoriesFilter: MarketAdvancedSearchViewModel.CategoryFilter) -> ColorStyle {
        switch categoriesFilter {
        case .any: return .secondary
        default: return .primary
        }
    }

    private func colorStyle(closeToFilter: MarketAdvancedSearchViewModel.PriceCloseToFilter) -> ColorStyle {
        switch closeToFilter {
        case .none: return .secondary
        default: return .primary
        }
    }

    private func colorStyle(priceChangeFilter: MarketAdvancedSearchViewModel.PriceChangeFilter) -> ColorStyle {
        switch priceChangeFilter {
        case .none: return .secondary
        case .plus10, .plus25, .plus50, .plus100: return .green
        case .minus10, .minus25, .minus50, .minus75: return .red
        }
    }
}

private struct AdvancedSearchHeaderModifier: ViewModifier {
    let imageName: String
    let title: String
    let isPresented: Binding<Bool>

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image(imageName).themeIcon(color: .themeJacob)
                Text(title.localized).themeHeadline2()
                IconButton(icon: "close", style: .secondary, mode: .transparent, size: .small) {
                    isPresented.wrappedValue = false
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.vertical, .margin24)

            content
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
        }
    }
}
