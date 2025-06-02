import Kingfisher
import MarketKit
import SwiftUI

struct MarketSearchView: View {
    @ObservedObject var viewModel: MarketSearchViewModel
    @ObservedObject var watchlistViewModel: WatchlistViewModel

    @State private var presentedCoin: Coin?

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
        .sheet(item: $presentedCoin) { coin in
            CoinPageView(coin: coin)
        }
    }

    @ViewBuilder private func itemContent(fullCoin: FullCoin) -> some View {
        let coin = fullCoin.coin

        ClickableRow(action: {
            viewModel.handleOpen(coinUid: coin.uid)
            presentedCoin = coin
        }) {
            CoinIconView(coin: coin)

            VStack(spacing: 1) {
                Text(coin.code).themeBody()
                Text(coin.name).themeSubhead2()
            }

            Spacer()

            WatchlistView.watchButton(viewModel: watchlistViewModel, coinUid: coin.uid)
                .contentShape(Rectangle())
                .onTapGesture {}
        }
    }
}
