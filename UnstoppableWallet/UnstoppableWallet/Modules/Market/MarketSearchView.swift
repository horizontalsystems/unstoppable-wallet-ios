import Kingfisher
import MarketKit
import SwiftUI
import ThemeKit

struct MarketSearchView: View {
    @ObservedObject var viewModel: MarketSearchViewModel

    @State private var presentedFullCoin: FullCoin?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case let .placeholder(recentFullCoins, popularFullCoins):
                ThemeLazyList {
                    if !recentFullCoins.isEmpty {
                        ThemeLazyListSection(header: "market.search.recent".localized, items: recentFullCoins) { fullCoin in
                            itemContent(fullCoin: fullCoin)
                        }
                    }

                    ThemeLazyListSection(header: "market.search.popular".localized, items: popularFullCoins) { fullCoin in
                        itemContent(fullCoin: fullCoin)
                    }
                }
                .themeListStyle(.transparent)
            case let .searchResults(fullCoins):
                ThemeList(items: fullCoins) { fullCoin in
                    itemContent(fullCoin: fullCoin)
                }
                .themeListStyle(.transparent)
            }
        }
        .sheet(item: $presentedFullCoin) { fullCoin in
            CoinPageViewNew(coinUid: fullCoin.coin.uid)
        }
    }

    @ViewBuilder private func itemContent(fullCoin: FullCoin) -> some View {
        ClickableRow(action: {
            viewModel.handleOpen(coinUid: fullCoin.coin.uid)
            presentedFullCoin = fullCoin
        }) {
            KFImage.url(URL(string: fullCoin.coin.imageUrl))
                .resizable()
                .placeholder { Circle().fill(Color.themeSteel20) }
                .frame(width: .iconSize32, height: .iconSize32)

            VStack(spacing: 1) {
                Text(fullCoin.coin.code).themeBody()
                Text(fullCoin.coin.name).themeSubhead2()
            }
        }
    }
}
