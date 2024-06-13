import Kingfisher
import MarketKit
import SwiftUI

struct MarketAdvancedSearchResultsView: View {
    @StateObject var viewModel: MarketAdvancedSearchResultsViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isParentPresented: Bool

    @State private var sortBySelectorPresented = false
    @State private var presentedCoin: Coin?

    init(marketInfos: [MarketInfo], timePeriod: HsTimePeriod, isParentPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketAdvancedSearchResultsViewModel(marketInfos: marketInfos, timePeriod: timePeriod))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .advancedSearchResults))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                header()

                ScrollViewReader { proxy in
                    ThemeList(viewModel.marketInfos, bottomSpacing: .margin16, invisibleTopView: true) { marketInfo in
                        let coin = marketInfo.fullCoin.coin

                        ClickableRow(action: {
                            presentedCoin = coin
                        }) {
                            itemContent(
                                coin: coin,
                                marketCap: marketInfo.marketCap,
                                price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                                rank: marketInfo.marketCapRank,
                                diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod)
                            )
                        }
                        .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
                    }
                    .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
                }
            }
        }
        .navigationTitle("market.advanced_search_results.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.close".localized) {
                    isParentPresented = false
                }
            }
        }
        .sheet(item: $presentedCoin) { coin in
            CoinPageView(coin: coin).ignoresSafeArea()
                .onFirstAppear { stat(page: .advancedSearchResults, event: .openCoin(coinUid: coin.uid)) }
        }
        .alert(
            isPresented: $sortBySelectorPresented,
            title: "market.sort_by.title".localized,
            viewItems: viewModel.sortBys.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.sortBy = viewModel.sortBys[index]
            }
        )
    }

    @ViewBuilder private func header() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    sortBySelectorPresented = true
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
        .alert(
            isPresented: $sortBySelectorPresented,
            title: "market.sort_by.title".localized,
            viewItems: viewModel.sortBys.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.sortBy = viewModel.sortBys[index]
            }
        )
    }

    @ViewBuilder private func itemContent(coin: Coin?, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?) -> some View {
        CoinIconView(coin: coin)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(coin?.code ?? "CODE").textBody()
                Spacer()
                Text(price).textBody()
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    if let rank {
                        BadgeViewNew(text: "\(rank)")
                    }

                    if let marketCap, let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: marketCap) {
                        Text(formatted).textSubhead2()
                    }
                }
                Spacer()
                DiffText(diff)
            }
        }
    }
}
