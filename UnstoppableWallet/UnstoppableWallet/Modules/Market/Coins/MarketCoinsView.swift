import Kingfisher
import MarketKit
import SwiftUI

struct MarketCoinsView: View {
    @ObservedObject var viewModel: MarketCoinsViewModel
    @ObservedObject var watchlistViewModel: WatchlistViewModel

    @State private var sortBySelectorPresented = false
    @State private var topSelectorPresented = false
    @State private var timePeriodSelectorPresented = false

    @State private var presentedFullCoin: FullCoin?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(marketInfos):
                VStack(spacing: 0) {
                    header()
                    list(marketInfos: marketInfos)
                }
            case .failed:
                SyncErrorView {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .sheet(item: $presentedFullCoin) { fullCoin in
            CoinPageViewNew(coinUid: fullCoin.coin.uid).ignoresSafeArea()
                .onFirstAppear { stat(page: .markets, section: .coins, event: .openCoin(coinUid: fullCoin.coin.uid)) }
        }
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    sortBySelectorPresented = true
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    topSelectorPresented = true
                }) {
                    Text(viewModel.top.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    timePeriodSelectorPresented = true
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)
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
        .alert(
            isPresented: $topSelectorPresented,
            title: "market.top_coins.title".localized,
            viewItems: viewModel.tops.map { .init(text: $0.title, selected: viewModel.top == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.top = viewModel.tops[index]
            }
        )
        .alert(
            isPresented: $timePeriodSelectorPresented,
            title: "market.time_period.title".localized,
            viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.timePeriod = viewModel.timePeriods[index]
            }
        )
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo]) -> some View {
        ThemeList(marketInfos) { marketInfo in
            let coin = marketInfo.fullCoin.coin

            ClickableRow(action: {
                presentedFullCoin = marketInfo.fullCoin
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
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { index in
            ListRow {
                itemContent(
                    coin: nil,
                    marketCap: 123_456,
                    price: "$123.45",
                    rank: 12,
                    diff: index % 2 == 0 ? 12.34 : -12.34
                )
                .redacted()
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
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
