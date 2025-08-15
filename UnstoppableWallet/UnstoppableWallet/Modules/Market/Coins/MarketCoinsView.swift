import Kingfisher
import MarketKit
import SwiftUI

struct MarketCoinsView: View {
    @ObservedObject var viewModel: MarketCoinsViewModel
    @ObservedObject var watchlistViewModel: WatchlistViewModel

    var body: some View {
        ThemeView(style: .list) {
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
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ListHeader(scrollable: true) {
            DropdownButton(text: viewModel.sortBy.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.sort_by.title".localized,
                        viewItems: viewModel.sortBys.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
                        onSelect: { index in
                            viewModel.sortBy = viewModel.sortBys[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)

            DropdownButton(text: viewModel.top.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.top_coins.title".localized,
                        viewItems: viewModel.tops.map { .init(text: $0.title, selected: viewModel.top == $0) },
                        onSelect: { index in
                            viewModel.top = viewModel.tops[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)

            DropdownButton(text: viewModel.timePeriod.shortTitle) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.time_period.title".localized,
                        viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
                        onSelect: { index in
                            viewModel.timePeriod = viewModel.timePeriods[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(marketInfos) { marketInfo in
                let coin = marketInfo.fullCoin.coin

                cell(
                    coin: coin,
                    marketCap: marketInfo.marketCap,
                    price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    rank: marketInfo.marketCapRank,
                    diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod)
                ) {
                    Coordinator.shared.presentCoinPage(coin: coin, page: .markets, section: .coins)
                }
                .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
            .onChange(of: viewModel.top) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
            .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { index in
            cell(
                coin: nil,
                marketCap: 123_456,
                price: "$123.45",
                rank: 12,
                diff: index % 2 == 0 ? 12.34 : -12.34
            )
            .redacted()
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(coin: Coin?, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                CoinIconView(coin: coin)
            },
            middle: {
                MultiText(
                    title: coin?.code ?? "CODE",
                    subtitleBadge: rank.map { "\($0)" },
                    subtitle: marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) }
                )
            },
            right: {
                RightMultiText(
                    title: price,
                    subtitle: Diff.text(diff: diff)
                )
            },
            action: action
        )
    }
}
