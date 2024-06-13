import MarketKit
import SwiftUI

struct CoinPageView: View {
    @StateObject private var viewModel: CoinPageViewModelNew

    @StateObject private var overviewViewModel: CoinOverviewViewModelNew
    @StateObject private var chartViewModel: CoinChartViewModel
    @StateObject private var analyticsViewModel: CoinAnalyticsViewModelNew
    @StateObject private var marketsViewModel: CoinMarketsViewModel

    @Environment(\.presentationMode) private var presentationMode

    @State private var currentTab: Tab = .overview
    @State private var loadedTabs = [Tab]()

    init(coin: Coin) {
        _viewModel = StateObject(wrappedValue: CoinPageViewModelNew(coin: coin))
        _overviewViewModel = StateObject(wrappedValue: CoinOverviewViewModelNew(coinUid: coin.uid))
        _chartViewModel = StateObject(wrappedValue: CoinChartViewModel.instance(coinUid: coin.uid))
        _analyticsViewModel = StateObject(wrappedValue: CoinAnalyticsViewModelNew(coin: coin))
        _marketsViewModel = StateObject(wrappedValue: CoinMarketsViewModel(coinUid: coin.uid))
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack(spacing: 0) {
                    TabHeaderView(
                        tabs: Tab.allCases.map(\.title),
                        currentTabIndex: Binding(
                            get: {
                                Tab.allCases.firstIndex(of: currentTab) ?? 0
                            },
                            set: { index in
                                currentTab = Tab.allCases[index]
                            }
                        )
                    )

                    VStack {
                        switch currentTab {
                        case .overview: CoinOverviewView(viewModel: overviewViewModel, chartViewModel: chartViewModel)
                        case .analytics: CoinAnalyticsView(viewModel: analyticsViewModel)
                        case .markets: CoinMarketsView(viewModel: marketsViewModel)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .onChange(of: currentTab) { tab in
                        load(tab: tab)
                    }
                    .onFirstAppear {
                        load(tab: currentTab)
                    }
                }
            }
            .navigationTitle(viewModel.coin.code)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.close".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isFavorite.toggle()
                    }) {
                        Image(viewModel.isFavorite ? "filled_star_24" : "star_24")
                            .renderingMode(.template)
                            .foregroundColor(viewModel.isFavorite ? .themeJacob : .themeGray)
                    }
                }
            }
        }
    }

    private func load(tab: Tab) {
        guard !loadedTabs.contains(tab) else {
            return
        }

        loadedTabs.append(tab)

        switch tab {
        case .overview: overviewViewModel.load()
        case .analytics: analyticsViewModel.load()
        case .markets: marketsViewModel.load()
        }
    }
}

extension CoinPageView {
    enum Tab: Int, CaseIterable {
        case overview
        case analytics
        case markets

        var title: String {
            switch self {
            case .overview: return "coin_page.overview".localized
            case .analytics: return "coin_page.analytics".localized
            case .markets: return "coin_page.markets".localized
            }
        }
    }
}
