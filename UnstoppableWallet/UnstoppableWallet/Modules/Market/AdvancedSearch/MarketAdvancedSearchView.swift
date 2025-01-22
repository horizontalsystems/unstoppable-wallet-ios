import MarketKit
import SwiftUI

struct MarketAdvancedSearchView: View {
    @StateObject var viewModel = MarketAdvancedSearchViewModel()
    @Binding var isPresented: Bool

    @State var topPresented = false
    @State var volumePresented = false
    @State var categoriesPresented = false
    @State var blockchainsPresented = false
    @State var signalsPresented = false
    @State var priceCloseToPresented = false
    @State var priceChangePresented = false
    @State var pricePeriodPresented = false
    @State var subscriptionPresented = false
    @State var resultsPresented = false

    var body: some View {
        ThemeNavigationView {
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
                                    premiumRow(outperformedBtcRow())
                                    premiumRow(outperformedEthRow())
                                    premiumRow(outperformedBnbRow())
                                }
                                .modifier(ColoredBorder())
                            }

                            VStack(spacing: 0) {
                                ListSection {
                                    premiumRow(goodCexVolumeRow())
                                    premiumRow(goodDexVolumeRow())
                                    premiumRow(goodDistributionRow())
                                    premiumRow(listedOnTopExchangesRow())
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
                    .disabled(!viewModel.canReset)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $subscriptionPresented) {
                PurchasesView()
            }
        }
    }

    @ViewBuilder private func topRow() -> some View {
        ClickableRow(spacing: .margin8) {
            topPresented = true
        } content: {
            Text("market.advanced_search.choose_set".localized).textBody()
            Spacer()
            Text(viewModel.top.title).textSubhead1(color: .themeLeah)
            Image("arrow_small_down_20").themeIcon()
        }
        .bottomSheet(isPresented: $topPresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("circle_coin_24").themeIcon(color: .themeJacob)
                    Text("market.advanced_search.choose_set".localized).themeHeadline2()
                    Button(action: { topPresented = false }) { Image("close_3_24").themeIcon() }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                ListSection {
                    ForEach(viewModel.tops) { top in
                        ClickableRow {
                            viewModel.top = top
                            topPresented = false
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
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
        }
    }

    @ViewBuilder private func volumeRow() -> some View {
        ClickableRow(spacing: .margin8) {
            volumePresented = true
        } content: {
            Text("market.advanced_search.volume".localized).textBody()
            Spacer()
            Text(viewModel.volume.title).textSubhead1(color: color(valueFilter: viewModel.volume))
            Image("arrow_small_down_20").themeIcon()
        }
        .bottomSheet(isPresented: $volumePresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("chart_2_24").themeIcon(color: .themeJacob)
                    Text("market.advanced_search.volume".localized).themeHeadline2()
                    Button(action: { volumePresented = false }) { Image("close_3_24").themeIcon() }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                ListSection {
                    ForEach(viewModel.valueFilters) { filter in
                        ClickableRow {
                            viewModel.volume = filter
                            volumePresented = false
                        } content: {
                            Text(filter.title).themeBody(color: color(valueFilter: filter))

                            if viewModel.volume == filter {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
        }
    }

    @ViewBuilder private func categoriesRow() -> some View {
        ClickableRow(spacing: .margin8) {
            categoriesPresented = true
        } content: {
            Text("market.advanced_search.categories".localized).textBody()
            Spacer()
            Text(viewModel.categories.title).textSubhead1(color: color(categoriesFilter: viewModel.categories))
            Image("arrow_small_down_20").themeIcon()
        }
        .sheet(isPresented: $categoriesPresented) {
            MarketAdvancedSearchCategoriesView(viewModel: viewModel, isPresented: $categoriesPresented)
        }
    }

    @ViewBuilder private func premiumRow(_ view: some View) -> some View {
        if viewModel.premiumEnabled {
            ListRow {
                view
            }
        } else {
            ClickableRow {
                subscriptionPresented = true
            } content: {
                view
            }
        }
    }

    @ViewBuilder private func listedOnTopExchangesRow() -> some View {
        Toggle(isOn: $viewModel.listedOnTopExchanges) {
            Text("market.advanced_search.listed_on_top_exchanges".localized).themeBody()
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func goodCexVolumeRow() -> some View {
        Toggle(isOn: $viewModel.goodCexVolume) {
            VStack(spacing: 1) {
                Text("market.advanced_search.good_cex_volume".localized).themeBody()
                Text("market.advanced_search.overall_score_is_good_or_excellent".localized).themeSubhead2()
            }
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func goodDexVolumeRow() -> some View {
        Toggle(isOn: $viewModel.goodDexVolume) {
            VStack(spacing: 1) {
                Text("market.advanced_search.good_dex_volume".localized).themeBody()
                Text("market.advanced_search.overall_score_is_good_or_excellent".localized).themeSubhead2()
            }
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func goodDistributionRow() -> some View {
        Toggle(isOn: $viewModel.goodDistribution) {
            VStack(spacing: 1) {
                Text("market.advanced_search.good_distribution".localized).themeBody()
                Text("market.advanced_search.overall_score_is_good_or_excellent".localized).themeSubhead2()
            }
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func blockchainsRow() -> some View {
        ClickableRow(spacing: .margin8) {
            blockchainsPresented = true
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
        .sheet(isPresented: $blockchainsPresented) {
            MarketAdvancedSearchBlockchainsView(viewModel: viewModel, isPresented: $blockchainsPresented)
        }
    }

    @ViewBuilder private func signalRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.premiumEnabled else {
                subscriptionPresented = true
                return
            }
            signalsPresented = true
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
        .bottomSheet(isPresented: $signalsPresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("bell_ring_24").themeIcon(color: .themeJacob)
                    Text("market.advanced_search.signal".localized).themeHeadline2()
                    Button(action: { signalsPresented = false }) { Image("close_3_24").themeIcon() }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                ListSection {
                    ClickableRow {
                        viewModel.signal = nil
                        signalsPresented = false
                    } content: {
                        Text("selector.any".localized).themeBody(color: .themeGray)

                        if viewModel.signal == nil {
                            Image("check_1_20").themeIcon(color: .themeJacob)
                        }
                    }

                    ForEach(viewModel.signals) { signal in
                        ClickableRow {
                            viewModel.signal = signal
                            signalsPresented = false
                        } content: {
                            Text(signal.title).themeBody()

                            if viewModel.signal == signal {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
        }
    }

    @ViewBuilder private func priceChangeRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.premiumEnabled else {
                subscriptionPresented = true
                return
            }
            priceChangePresented = true
        } content: {
            Text("market.advanced_search.price_change".localized).textBody()
            Spacer()
            Text(viewModel.priceChange.title).textSubhead1(color: color(priceChangeFilter: viewModel.priceChange))
            Image("arrow_small_down_20").themeIcon()
        }
        .bottomSheet(isPresented: $priceChangePresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("markets_24").themeIcon(color: .themeJacob)
                    Text("market.advanced_search.price_change".localized).themeHeadline2()
                    Button(action: { priceChangePresented = false }) { Image("close_3_24").themeIcon() }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                ListSection {
                    ForEach(MarketAdvancedSearchViewModel.PriceChangeFilter.allCases) { filter in
                        ClickableRow {
                            viewModel.priceChange = filter
                            priceChangePresented = false
                        } content: {
                            Text(filter.title).themeBody(color: color(priceChangeFilter: filter))

                            if viewModel.priceChange == filter {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
        }
    }

    @ViewBuilder private func pricePeriodRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.premiumEnabled else {
                subscriptionPresented = true
                return
            }
            pricePeriodPresented = true
        } content: {
            Text("market.advanced_search.price_period".localized).textBody()
            Spacer()
            Text(viewModel.priceChangePeriod.title).textSubhead1(color: .themeLeah)
            Image("arrow_small_down_20").themeIcon()
        }
        .bottomSheet(isPresented: $pricePeriodPresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("circle_clock_24").themeIcon(color: .themeJacob)
                    Text("market.advanced_search.price_period".localized).themeHeadline2()
                    Button(action: { pricePeriodPresented = false }) { Image("close_3_24").themeIcon() }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                ListSection {
                    ForEach(viewModel.priceChangePeriods) { period in
                        ClickableRow {
                            viewModel.priceChangePeriod = period
                            pricePeriodPresented = false
                        } content: {
                            Text(period.title).themeBody()

                            if viewModel.priceChangePeriod == period {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
        }
    }

    @ViewBuilder private func outperformedBtcRow() -> some View {
        Toggle(isOn: $viewModel.outperformedBtc) {
            Text("market.advanced_search.outperformed_btc".localized).themeBody()
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func outperformedEthRow() -> some View {
        Toggle(isOn: $viewModel.outperformedEth) {
            Text("market.advanced_search.outperformed_eth".localized).themeBody()
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func outperformedBnbRow() -> some View {
        Toggle(isOn: $viewModel.outperformedBnb) {
            Text("market.advanced_search.outperformed_bnb".localized).themeBody()
        }
        .disabled(!viewModel.premiumEnabled)
        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
    }

    @ViewBuilder private func priceCloseToRow() -> some View {
        ClickableRow(spacing: .margin8) {
            guard viewModel.premiumEnabled else {
                subscriptionPresented = true
                return
            }
            priceCloseToPresented = true
        } content: {
            Text("market.advanced_search.price_close_to".localized).textBody()
            Spacer()
            Text(viewModel.priceCloseTo.title).textSubhead1(color: color(closeToFilter: viewModel.priceCloseTo))
            Image("arrow_small_down_20").themeIcon()
        }
        .bottomSheet(isPresented: $priceCloseToPresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin16) {
                    Image("arrow_swap_24").themeIcon(color: .themeJacob)
                    Text("market.advanced_search.price_close_to".localized).themeHeadline2()
                    Button(action: { priceCloseToPresented = false }) { Image("close_3_24").themeIcon() }
                }
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin24)

                ListSection {
                    ForEach(MarketAdvancedSearchViewModel.PriceCloseToFilter.allCases) { closeTo in
                        ClickableRow {
                            viewModel.priceCloseTo = closeTo
                            priceCloseToPresented = false
                        } content: {
                            Text(closeTo.title).themeBody(color: color(closeToFilter: closeTo))

                            if viewModel.priceCloseTo == closeTo {
                                Image("check_1_20").themeIcon(color: .themeJacob)
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
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
