import SwiftUI

struct MarketTabView: View {
    @StateObject var viewModel = MarketTabViewModel()

    @StateObject var watchlistViewModel = WatchlistViewModel(page: .markets, section: .coins)
    @StateObject var coinsViewModel = MarketCoinsViewModel()
    @StateObject var marketWatchlistViewModel = MarketWatchlistViewModel()

    @State private var loadedTabs = [MarketModule.Tab]()

    var body: some View {
        VStack(spacing: 0) {
            ScrollableTabHeaderView(
                tabs: MarketModule.Tab.allCases.map { .init(title: $0.title, highlighted: false) },
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
        }
    }
}
