import SwiftUI
import ThemeKit

struct MarketTabView: View {
    @StateObject var coinsViewModel: MarketCoinsViewModel
    @StateObject var watchlistViewModel: MarketWatchlistViewModel

    @State private var currentTabIndex: Int = Tab.coins.rawValue
    @State private var loadedTabs = [Tab]()

    init() {
        _coinsViewModel = StateObject(wrappedValue: MarketCoinsViewModel())
        _watchlistViewModel = StateObject(wrappedValue: MarketWatchlistViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollableTabHeaderView(
                tabs: Tab.allCases.map(\.title),
                currentTabIndex: $currentTabIndex
            )

            TabView(selection: $currentTabIndex) {
                MarketCoinsView(viewModel: coinsViewModel)
                    .tag(Tab.coins.rawValue)

                MarketWatchlistView(viewModel: watchlistViewModel)
                    .tag(Tab.watchlist.rawValue)

                Text("News Content").tag(Tab.news.rawValue)
                Text("Platforms Content").tag(Tab.platforms.rawValue)
                Text("Pairs Content").tag(Tab.pairs.rawValue)
                Text("Sectors Content").tag(Tab.sectors.rawValue)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
            .onChange(of: currentTabIndex) { index in
                loadTab(index: index)
            }
            .onFirstAppear {
                loadTab(index: currentTabIndex)
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
        case .news: ()
        case .platforms: ()
        case .pairs: ()
        case .sectors: ()
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
        case sectors

        var title: String {
            switch self {
            case .coins: return "market.tab.coins".localized
            case .watchlist: return "market.tab.watchlist".localized
            case .news: return "market.tab.news".localized
            case .platforms: return "market.tab.platforms".localized
            case .pairs: return "market.tab.pairs".localized
            case .sectors: return "market.tab.sectors".localized
            }
        }
    }
}
