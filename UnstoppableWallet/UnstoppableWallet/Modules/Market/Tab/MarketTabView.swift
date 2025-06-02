import SwiftUI

struct MarketTabView: View {
    @StateObject var viewModel: MarketTabViewModel
    @ObservedObject var watchlistViewModel: WatchlistViewModel

    @StateObject var coinsViewModel: MarketCoinsViewModel
    @StateObject var marketWatchlistViewModel: MarketWatchlistViewModel
    @StateObject var newsViewModel: MarketNewsViewModel
    @StateObject var platformsViewModel: MarketPlatformsViewModel
    @StateObject var pairsViewModel: MarketPairsViewModel
    @StateObject var sectorsViewModel: MarketSectorsViewModel

    @State private var loadedTabs = [MarketModule.Tab]()

    init(watchlistViewModel: WatchlistViewModel) {
        _viewModel = StateObject(wrappedValue: MarketTabViewModel())
        self.watchlistViewModel = watchlistViewModel

        _coinsViewModel = StateObject(wrappedValue: MarketCoinsViewModel())
        _marketWatchlistViewModel = StateObject(wrappedValue: MarketWatchlistViewModel())
        _newsViewModel = StateObject(wrappedValue: MarketNewsViewModel())
        _platformsViewModel = StateObject(wrappedValue: MarketPlatformsViewModel())
        _pairsViewModel = StateObject(wrappedValue: MarketPairsViewModel())
        _sectorsViewModel = StateObject(wrappedValue: MarketSectorsViewModel())
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
                case .coins: MarketCoinsView(viewModel: coinsViewModel, watchlistViewModel: watchlistViewModel)
                case .watchlist: MarketWatchlistView(viewModel: marketWatchlistViewModel)
                case .news: MarketNewsView(viewModel: newsViewModel)
                case .platforms: MarketPlatformsView(viewModel: platformsViewModel)
                case .pairs: MarketPairsView(viewModel: pairsViewModel)
                case .sectors: MarketSectorsView(viewModel: sectorsViewModel)
                }
            }
            .frame(maxHeight: .infinity)
            .onChange(of: viewModel.currentTab) { tab in
                stat(page: .markets, event: .switchTab(tab: tab.statTab))
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
        case .watchlist: marketWatchlistViewModel.load()
        case .news: newsViewModel.load()
        case .platforms: platformsViewModel.load()
        case .pairs: pairsViewModel.load()
        case .sectors: sectorsViewModel.load()
        }
    }
}
