import SwiftUI
import ThemeKit

struct MarketTabView: View {
    @StateObject var viewModel: MarketTabViewModel

    @StateObject var coinsViewModel: MarketCoinsViewModel
    @StateObject var watchlistViewModel: MarketWatchlistViewModel
    @StateObject var newsViewModel: MarketNewsViewModel
    @StateObject var platformsViewModel: MarketPlatformsViewModel
    @StateObject var pairsViewModel: MarketPairsViewModel

    @State private var loadedTabs = [MarketModule.Tab]()

    init() {
        _viewModel = StateObject(wrappedValue: MarketTabViewModel())

        _coinsViewModel = StateObject(wrappedValue: MarketCoinsViewModel())
        _watchlistViewModel = StateObject(wrappedValue: MarketWatchlistViewModel())
        _newsViewModel = StateObject(wrappedValue: MarketNewsViewModel())
        _platformsViewModel = StateObject(wrappedValue: MarketPlatformsViewModel())
        _pairsViewModel = StateObject(wrappedValue: MarketPairsViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollableTabHeaderView(
                tabs: MarketModule.Tab.allCases.map(\.title),
                currentTabIndex: Binding(
                    get: {
                        MarketModule.Tab.allCases.firstIndex(of: viewModel.currentTab) ?? 0
                    },
                    set: { index in
                        viewModel.currentTab = MarketModule.Tab.allCases[index]
                    }
                )
            )

            VStack {
                switch viewModel.currentTab {
                case .coins: MarketCoinsView(viewModel: coinsViewModel)
                case .watchlist: MarketWatchlistView(viewModel: watchlistViewModel)
                case .news: MarketNewsView(viewModel: newsViewModel)
                case .platforms: MarketPlatformsView(viewModel: platformsViewModel)
                case .pairs: MarketPairsView(viewModel: pairsViewModel)
                }
            }
            .frame(maxHeight: .infinity)
            .onChange(of: viewModel.currentTab) { tab in
                load(tab: tab)
            }
            .onFirstAppear {
                load(tab: viewModel.currentTab)
            }
        }
    }

    private func load(tab: MarketModule.Tab) {
        guard !loadedTabs.contains(tab) else {
            return
        }

        loadedTabs.append(tab)

        switch tab {
        case .coins: coinsViewModel.load()
        case .watchlist: watchlistViewModel.load()
        case .news: newsViewModel.load()
        case .platforms: platformsViewModel.load()
        case .pairs: pairsViewModel.load()
        }
    }
}
