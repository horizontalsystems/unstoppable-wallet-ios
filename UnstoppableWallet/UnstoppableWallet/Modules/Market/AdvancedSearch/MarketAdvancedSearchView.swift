import MarketKit
import SwiftUI

struct MarketAdvancedSearchView: View {
    @StateObject var viewModel = MarketAdvancedSearchViewModel()
    @Binding var isPresented: Bool

    @State var resultsPresented = false

    var body: some View {
        ThemeNavigationStack {
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
                                    premiumRow(outperformedBtcRow(), statPremiumKey: .outperformedBtc)
                                    premiumRow(outperformedEthRow(), statPremiumKey: .outperformedEth)
                                    premiumRow(outperformedBnbRow(), statPremiumKey: .outperformedBnb)
                                    premiumRow(outperformedSp500Row(), statPremiumKey: .outperformedSp500)
                                    premiumRow(outperformedGoldRow(), statPremiumKey: .outperformedGold)
                                }
                                .modifier(ColoredBorder())
                            }

                            VStack(spacing: 0) {
                                ListSection {
                                    premiumRow(goodCexVolumeRow(), statPremiumKey: .goodCexVolume)
                                    premiumRow(goodDexVolumeRow(), statPremiumKey: .goodDexVolume)
                                    premiumRow(goodDistributionRow(), statPremiumKey: .goodDistribution)
                                    premiumRow(listedOnTopExchangesRow(), statPremiumKey: .listedOnTopExchanges)
                                }
                                .modifier(ColoredBorder())
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    switch viewModel.state {
                    case .loading:
                        Button {} label: { ProgressView() }
                            .buttonStyle(PrimaryButtonStyle(style: .yellow))
                            .disabled(true)
                    case let .loaded(marketInfos):
                        Button {
                            resultsPresented = true
                        } label: {
                            Text(marketInfos.isEmpty ? "market.advanced_search.empty_results".localized : "\("market.advanced_search.show_results".localized): \(marketInfos.count)")
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))
                        .disabled(marketInfos.isEmpty)
                    case .failed:
                        Button {
                            viewModel.syncMarketInfos()
                        } label: {
                            Text("market.advanced_search.retry".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))
                    }
                }

                NavigationLink(
                    isActive: $resultsPresented,
                    destination: {
                        if case let .loaded(marketInfos) = viewModel.state {
                            MarketAdvancedSearchResultsView(marketInfos: marketInfos, timePeriod: viewModel.priceChangePeriod, isParentPresented: $isPresented)
                        }
                    }
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("market.advanced_search.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("market.advanced_search.reset_all".localized) {
                        viewModel.reset()
                    }
                    .foregroundStyle(viewModel.canReset ? Color.themeJacob : Color.themeGray)
                    .disabled(!viewModel.canReset)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func topRow() -> some View {
        ClickableRow(spacing: .margin8) {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(viewModel.tops) { top in
                        ClickableRow {
                            viewModel.top = top
                            isPresented.wrappedValue = false
                        } content: {
                            VStack(spacing: 1) {
                                Text(top.title).themeBody()
                                Text(top.description).themeSubhead2()
                            }

                            if viewModel.top == top {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "circle_coin_24", title: "market.advanced_search.choose_set", isPresented: isPresented))
            }
        } content: {
            Text("market.advanced_search.choose_set".localized).textBody()
            Spacer()
            Text(viewModel.top.title).textSubhead1(color: .themeLeah)
            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func volumeRow() -> some View {
        ClickableRow(spacing: .margin8) {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(viewModel.valueFilters) { filter in
                        ClickableRow {
                            viewModel.volume = filter
                            isPresented.wrappedValue = false
                        } content: {
                            Text(filter.title).themeBody(color: color(valueFilter: filter))

                            if viewModel.volume == filter {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "chart_2_24", title: "market.advanced_search.volume", isPresented: isPresented))
            }
        } content: {
            Text("market.advanced_search.volume".localized).textBody()
            Spacer()
            Text(viewModel.volume.title).textSubhead1(color: color(valueFilter: viewModel.volume))
            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func categoriesRow() -> some View {
        ClickableRow(spacing: .margin8) {
            if viewModel.advancedSearchEnabled {
                Coordinator.shared.present { isPresented in
                    MarketAdvancedSearchCategoriesView(viewModel: viewModel, isPresented: isPresented)
                }
            } else {
                Coordinator.shared.presentPurchases()
                stat(page: .advancedSearch, event: .openPremium(from: .sectors))
            }
        } content: {
            Text("market.advanced_search.categories".localized).textBody()
            Spacer()
            Text(viewModel.categories.title).textSubhead1(color: color(categoriesFilter: viewModel.categories))
            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func premiumRow(_ view: some View, statPremiumKey: StatPremiumTrigger) -> some View {
        if viewModel.advancedSearchEnabled {
            ListRow {
                view
            }
        } else {
            ClickableRow {
                Coordinator.shared.presentPurchases()
                stat(page: .advancedSearch, event: .openPremium(from: statPremiumKey))
            } content: {
                view
            }
        }
    }

    @ViewBuilder private func listedOnTopExchangesRow() -> some View {
        Toggle(isOn: $viewModel.listedOnTopExchanges) {
            Text("market.advanced_search.listed_on_top_exchanges".localized).themeBody()
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func goodCexVolumeRow() -> some View {
        Toggle(isOn: $viewModel.goodCexVolume) {
            VStack(spacing: 1) {
                Text("market.advanced_search.good_cex_volume".localized).themeBody()
                Text("market.advanced_search.overall_score_is_good_or_excellent".localized).themeSubhead2()
            }
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func goodDexVolumeRow() -> some View {
        Toggle(isOn: $viewModel.goodDexVolume) {
            VStack(spacing: 1) {
                Text("market.advanced_search.good_dex_volume".localized).themeBody()
                Text("market.advanced_search.overall_score_is_good_or_excellent".localized).themeSubhead2()
            }
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func goodDistributionRow() -> some View {
        Toggle(isOn: $viewModel.goodDistribution) {
            VStack(spacing: 1) {
                Text("market.advanced_search.good_distribution".localized).themeBody()
                Text("market.advanced_search.overall_score_is_good_or_excellent".localized).themeSubhead2()
            }
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func blockchainsRow() -> some View {
        ClickableRow(spacing: .margin8) {
            Coordinator.shared.present { isPresented in
                MarketAdvancedSearchBlockchainsView(viewModel: viewModel, isPresented: isPresented)
            }
        } content: {
            Text("market.advanced_search.blockchains".localized).textBody()
            Spacer()

            if viewModel.blockchains.isEmpty {
                Text("selector.any".localized).textSubhead1()
            } else if viewModel.blockchains.count == 1, let blockchain = viewModel.blockchains.first {
                Text(blockchain.name).textSubhead1(color: .themeLeah)
            } else {
                Text("\(viewModel.blockchains.count)").textSubhead1(color: .themeLeah)
            }

            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func signalRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.advancedSearchEnabled else {
                Coordinator.shared.presentPurchases()
                stat(page: .advancedSearch, event: .openPremium(from: .tradingSignal))
                return
            }
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ClickableRow {
                        viewModel.signal = nil
                        isPresented.wrappedValue = false
                    } content: {
                        Text("selector.any".localized).themeBody(color: .themeGray)

                        if viewModel.signal == nil {
                            Image("check_1_20").themeIcon(color: .themeJacob)
                        }
                    }

                    ForEach(viewModel.signals) { signal in
                        ClickableRow {
                            viewModel.signal = signal
                            isPresented.wrappedValue = false
                        } content: {
                            Text(signal.title).themeBody()

                            if viewModel.signal == signal {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "bell_ring_24", title: "market.advanced_search.signal", isPresented: isPresented))
            }
        } content: {
            Text("market.advanced_search.signal".localized).textBody()
            Spacer()

            if let signal = viewModel.signal {
                Text(signal.title).textSubhead1(color: .themeLeah)
            } else {
                Text("selector.any".localized).textSubhead1()
            }

            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func priceChangeRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.advancedSearchEnabled else {
                Coordinator.shared.presentPurchases()
                stat(page: .advancedSearch, event: .openPremium(from: .priceChange))
                return
            }
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(MarketAdvancedSearchViewModel.PriceChangeFilter.allCases) { filter in
                        ClickableRow {
                            viewModel.priceChange = filter
                            isPresented.wrappedValue = false
                        } content: {
                            Text(filter.title).themeBody(color: color(priceChangeFilter: filter))

                            if viewModel.priceChange == filter {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "markets_24", title: "market.advanced_search.price_change", isPresented: isPresented))
            }
        } content: {
            Text("market.advanced_search.price_change".localized).textBody()
            Spacer()
            Text(viewModel.priceChange.title).textSubhead1(color: color(priceChangeFilter: viewModel.priceChange))
            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func pricePeriodRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.advancedSearchEnabled else {
                Coordinator.shared.presentPurchases()
                stat(page: .advancedSearch, event: .openPremium(from: .pricePeriod))
                return
            }
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(viewModel.priceChangePeriods) { period in
                        ClickableRow {
                            viewModel.priceChangePeriod = period
                            isPresented.wrappedValue = false
                        } content: {
                            Text(period.title).themeBody()

                            if viewModel.priceChangePeriod == period {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "circle_clock_24", title: "market.advanced_search.price_period", isPresented: isPresented))
            }
        } content: {
            Text("market.advanced_search.price_period".localized).textBody()
            Spacer()
            Text(viewModel.priceChangePeriod.title).textSubhead1(color: .themeLeah)
            Image("arrow_small_down_20").themeIcon()
        }
    }

    @ViewBuilder private func outperformedBtcRow() -> some View {
        Toggle(isOn: $viewModel.outperformedBtc) {
            Text("market.advanced_search.outperformed_btc".localized).themeBody()
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func outperformedEthRow() -> some View {
        Toggle(isOn: $viewModel.outperformedEth) {
            Text("market.advanced_search.outperformed_eth".localized).themeBody()
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func outperformedBnbRow() -> some View {
        Toggle(isOn: $viewModel.outperformedBnb) {
            Text("market.advanced_search.outperformed_bnb".localized).themeBody()
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func outperformedSp500Row() -> some View {
        Toggle(isOn: $viewModel.outperformedSp500) {
            Text("market.advanced_search.outperformed_sp500".localized).themeBody()
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func outperformedGoldRow() -> some View {
        Toggle(isOn: $viewModel.outperformedGold) {
            Text("market.advanced_search.outperformed_gold".localized).themeBody()
        }
        .disabled(!viewModel.advancedSearchEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func priceCloseToRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.advancedSearchEnabled else {
                Coordinator.shared.presentPurchases()
                stat(page: .advancedSearch, event: .openPremium(from: .priceCloseTo))
                return
            }
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                ListSection {
                    ForEach(MarketAdvancedSearchViewModel.PriceCloseToFilter.allCases) { closeTo in
                        ClickableRow {
                            viewModel.priceCloseTo = closeTo
                            isPresented.wrappedValue = false
                        } content: {
                            Text(closeTo.title).themeBody(color: color(closeToFilter: closeTo))

                            if viewModel.priceCloseTo == closeTo {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(AdvancedSearchHeaderModifier(imageName: "arrow_swap_24", title: "market.advanced_search.price_close_to", isPresented: isPresented))
            }
        } content: {
            Text("market.advanced_search.price_close_to".localized).textBody()
            Spacer()
            Text(viewModel.priceCloseTo.title).textSubhead1(color: color(closeToFilter: viewModel.priceCloseTo))
            Image("arrow_small_down_20").themeIcon()
        }
    }

    private func color(valueFilter: MarketAdvancedSearchViewModel.ValueFilter) -> Color {
        switch valueFilter {
        case .none: return .themeGray
        default: return .themeLeah
        }
    }

    private func color(categoriesFilter: MarketAdvancedSearchViewModel.CategoryFilter) -> Color {
        switch categoriesFilter {
        case .any: return .themeGray
        default: return .themeLeah
        }
    }

    private func color(closeToFilter: MarketAdvancedSearchViewModel.PriceCloseToFilter) -> Color {
        switch closeToFilter {
        case .none: return .themeGray
        default: return .themeLeah
        }
    }

    private func color(priceChangeFilter: MarketAdvancedSearchViewModel.PriceChangeFilter) -> Color {
        switch priceChangeFilter {
        case .none: return .themeGray
        case .plus10, .plus25, .plus50, .plus100: return .themeRemus
        case .minus10, .minus25, .minus50, .minus75: return .themeLucian
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
                Button(action: { isPresented.wrappedValue = false }) { Image("close_3_24").themeIcon() }
            }
            .padding(.horizontal, .margin32)
            .padding(.vertical, .margin24)

            content
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
        }
    }
}
