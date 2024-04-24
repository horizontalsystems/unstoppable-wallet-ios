import SwiftUI
import ThemeKit

struct MarketTabView: View {
    @StateObject var coinsViewModel: MarketCoinsViewModel

    @State private var currentTabIndex: Int = Tab.coins.rawValue

    init() {
        _coinsViewModel = StateObject(wrappedValue: MarketCoinsViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollableTabHeaderView(
                tabs: Tab.allCases.map(\.title),
                currentTabIndex: $currentTabIndex
            )

            TabView(selection: $currentTabIndex) {
                Text("News Content").tag(Tab.news.rawValue)

                MarketCoinsView(viewModel: coinsViewModel)
                    .tag(Tab.coins.rawValue)

                Text("Watchlist Content").tag(Tab.watchlist.rawValue)
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

        switch tab {
        case .news: ()
        case .coins: coinsViewModel.sync()
        case .watchlist: ()
        case .platforms: ()
        case .pairs: ()
        case .sectors: ()
        }
    }
}

extension MarketTabView {
    enum Tab: Int, CaseIterable {
        case news
        case coins
        case watchlist
        case platforms
        case pairs
        case sectors

        var title: String {
            switch self {
            case .news: return "market.tab.news".localized
            case .coins: return "market.tab.coins".localized
            case .watchlist: return "market.tab.watchlist".localized
            case .platforms: return "market.tab.platforms".localized
            case .pairs: return "market.tab.pairs".localized
            case .sectors: return "market.tab.sectors".localized
            }
        }
    }
}
