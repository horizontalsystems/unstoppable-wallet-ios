import Kingfisher
import MarketKit
import SwiftUI
import ThemeKit

struct MarketSearchView: View {
    @ObservedObject var viewModel: MarketSearchViewModel
    @ObservedObject var watchlistViewModel: WatchlistViewModel

    @State private var presentedFullCoin: FullCoin?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case let .placeholder(recentFullCoins, popularFullCoins):
                ThemeList {
                    if !recentFullCoins.isEmpty {
                        Section {
                            ListForEach(recentFullCoins) { fullCoin in
                                itemContent(fullCoin: fullCoin)
                            }
                        } header: {
                            ThemeListSectionHeader(text: "market.search.recent".localized)
                        }
                    }

                    Section {
                        ListForEach(popularFullCoins) { fullCoin in
                            itemContent(fullCoin: fullCoin)
                        }
                    } header: {
                        ThemeListSectionHeader(text: "market.search.popular".localized)
                    }
                }
            case let .searchResults(fullCoins):
                ThemeList {
                    ListForEach(fullCoins) { fullCoin in
                        itemContent(fullCoin: fullCoin)
                    }
                }
            }
        }
        .sheet(item: $presentedFullCoin) { fullCoin in
            CoinPageViewNew(coinUid: fullCoin.coin.uid)
        }
    }

    @ViewBuilder private func itemContent(fullCoin: FullCoin) -> some View {
        let coin = fullCoin.coin

        ClickableRow(action: {
            viewModel.handleOpen(coinUid: coin.uid)
            presentedFullCoin = fullCoin
        }) {
            CoinIconView(coin: coin)

            VStack(spacing: 1) {
                Text(coin.code).themeBody()
                Text(coin.name).themeSubhead2()
            }
        }
        .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
    }
}
