import Kingfisher
import MarketKit
import SwiftUI

struct MarketSearchView: View {
    @StateObject var viewModel = MarketSearchViewModel()
    @StateObject var watchlistViewModel = WatchlistViewModel(page: .marketSearch)

    @Binding var isPresented: Bool
    @State private var path = NavigationPath()
    @State private var advancedSearchPresented = false

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
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
                    if fullCoins.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "alert.not_founded".localized)
                    } else {
                        ThemeList {
                            ListForEach(fullCoins) { fullCoin in
                                itemContent(fullCoin: fullCoin)
                            }
                        }
                    }
                }
            }
            .navigationTitle("market.search.title".localized)
            .searchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)
            .navigationDestination(isPresented: $advancedSearchPresented) {
                MarketAdvancedSearchView(isParentPresented: $isPresented)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        advancedSearchPresented = true
                    }) {
                        Image("manage")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }

    @ViewBuilder private func itemContent(fullCoin: FullCoin) -> some View {
        let coin = fullCoin.coin

        ClickableRow(action: {
            viewModel.handleOpen(coinUid: coin.uid)
            Coordinator.shared.presentCoinPage(coin: coin, page: .marketSearch)
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
