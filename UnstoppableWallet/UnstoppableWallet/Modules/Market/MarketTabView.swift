import SwiftUI
import ThemeKit

struct MarketTabView: View {
    @StateObject var coinsViewModel: MarketCoinsViewModel
    @StateObject var watchlistViewModel: MarketWatchlistViewModel
    @StateObject var newsViewModel: MarketNewsViewModel
    @StateObject var platformsViewModel: MarketPlatformsViewModel
    @StateObject var pairsViewModel: MarketPairsViewModel

    @State private var currentTabIndex: Int = Tab.pairs.rawValue
    @State private var loadedTabs = [Tab]()

    init() {
        _coinsViewModel = StateObject(wrappedValue: MarketCoinsViewModel())
        _watchlistViewModel = StateObject(wrappedValue: MarketWatchlistViewModel())
        _newsViewModel = StateObject(wrappedValue: MarketNewsViewModel())
        _platformsViewModel = StateObject(wrappedValue: MarketPlatformsViewModel())
        _pairsViewModel = StateObject(wrappedValue: MarketPairsViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollableTabHeaderView(
                tabs: Tab.allCases.map(\.title),
                currentTabIndex: $currentTabIndex
            )

            if let tab = Tab(rawValue: currentTabIndex) {
                VStack {
                    switch tab {
                    case .coins: MarketCoinsView(viewModel: coinsViewModel)
                    case .watchlist: MarketWatchlistView(viewModel: watchlistViewModel)
                    case .news: MarketNewsView(viewModel: newsViewModel)
                    case .platforms: MarketPlatformsView(viewModel: platformsViewModel)
                    case .pairs: MarketPairsView(viewModel: pairsViewModel)
                    }
                }
                .frame(maxHeight: .infinity)
                .onChange(of: currentTabIndex) { index in
                    loadTab(index: index)
                }
                .onFirstAppear {
                    loadTab(index: currentTabIndex)
                }
            }
        }
    }

    private func loadTab(index: Int) {
        guard let tab = Tab(rawValue: index) else {
            return
        }

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

extension MarketTabView {
    enum Tab: Int, CaseIterable {
        case coins
        case watchlist
        case news
        case platforms
        case pairs
        // case sectors

        var title: String {
            switch self {
            case .coins: return "market.tab.coins".localized
            case .watchlist: return "market.tab.watchlist".localized
            case .news: return "market.tab.news".localized
            case .platforms: return "market.tab.platforms".localized
            case .pairs: return "market.tab.pairs".localized
                // case .sectors: return "market.tab.sectors".localized
            }
        }
    }
}
