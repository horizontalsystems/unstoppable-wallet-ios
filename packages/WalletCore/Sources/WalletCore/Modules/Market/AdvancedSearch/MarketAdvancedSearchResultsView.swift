import Kingfisher
import MarketKit
import SwiftUI

struct MarketAdvancedSearchResultsView: View {
    @StateObject var viewModel: MarketAdvancedSearchResultsViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isParentPresented: Bool

    init(marketInfos: [MarketInfo], timePeriod: HsTimePeriod, isParentPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketAdvancedSearchResultsViewModel(marketInfos: marketInfos, timePeriod: timePeriod))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .advancedSearchResults))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                header()

                ScrollViewReader { proxy in
                    ThemeList(viewModel.marketInfos, bottomSpacing: .margin16) { marketInfo in
                        let coin = marketInfo.fullCoin.coin

                        cell(
                            coin: coin,
                            indicatorResult: marketInfo.indicatorsResult,
                            marketCap: marketInfo.marketCap,
                            price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                            rank: marketInfo.marketCapRank,
                            diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod)
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                }
            }
        }
        .navigationTitle("market.advanced_search_results.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isParentPresented = false
                }) {
                    Image("check")
                }
            }
        }
    }

    private func header() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
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

                ThemeButton(
                    text: "market.watchlist.signals".localized,
                    icon: "star_filled",
                    iconColorStyle: viewModel.showSignals ? nil : .yellow,
                    style: viewModel.showSignals ? .primary : .secondary,
                    size: .small
                ) {
                    Coordinator.shared.performAfterPurchase(premiumFeature: .advancedSearch, page: .advancedSearchResults, trigger: .tradingSignal) {
                        if viewModel.showSignals {
                            viewModel.set(showSignals: false)
                        } else {
                            Coordinator.shared.present { isPresented in
                                MarketWatchlistSignalsView(setShowSignals: { [weak viewModel] in
                                    viewModel?.set(showSignals: $0)
                                }, isPresented: isPresented)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
    }

    private func cell(coin: Coin, indicatorResult: TechnicalAdvice.Advice?, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?) -> some View {
        Cell(
            left: {
                CoinIconView(coin: coin)
            },
            middle: {
                MultiText(
                    title: coin.code,
                    badge: viewModel.showSignals ? indicatorResult.map { ComponentBadge(text: $0.title, mode: .transparent, colorStyle: $0.colorStyle) } : nil,
                    subtitleBadge: rank.map { "\($0)" },
                    subtitle: marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) }
                )
            },
            right: {
                HStack(spacing: 8) {
                    RightMultiText(
                        title: price,
                        subtitle: Diff.text(diff: diff)
                    )

                    WatchlistView.watchButton(viewModel: watchlistViewModel, coinUid: coin.uid)
                }
            },
            action: {
                Coordinator.shared.presentCoinPage(coin: coin, page: .advancedSearchResults)
            }
        )
    }
}
