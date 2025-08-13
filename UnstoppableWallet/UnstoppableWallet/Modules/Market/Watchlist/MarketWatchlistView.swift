import Kingfisher
import MarketKit
import SwiftUI

struct MarketWatchlistView: View {
    @ObservedObject var viewModel: MarketWatchlistViewModel

    @State private var editMode: EditMode = .inactive

    var body: some View {
        ThemeView(background: .themeLawrence) {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(marketInfos, signals):
                if marketInfos.isEmpty {
                    PlaceholderViewNew(image: Image("heart_48"), text: "market.watchlist.empty".localized)
                } else {
                    VStack(spacing: 0) {
                        header()
                        list(marketInfos: marketInfos, signals: signals)
                    }
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
                        viewItems: WatchlistSortBy.allCases.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
                        onSelect: { index in
                            viewModel.sortBy = WatchlistSortBy.allCases[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)

            if viewModel.sortBy == .manual {
                IconButton(icon: "pen", style: editMode == .active ? .primary : .secondary, size: .small) {
                    if editMode == .active {
                        editMode = .inactive
                    } else {
                        editMode = .active
                    }
                }
                .disabled(disabled)
            }

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

            ThemeButton(text: "market.watchlist.signals".localized, style: viewModel.showSignals ? .primary : .secondary, size: .small) {
                Coordinator.shared.performAfterPurchase(premiumFeature: .tradeSignals, page: .watchlist, trigger: .tradingSignal) {
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
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo], signals: [String: TechnicalAdvice.Advice]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(
                marketInfos,
                onMove: viewModel.sortBy == .manual ? { source, destination in
                    viewModel.move(source: source, destination: destination)
                } : nil
            ) { marketInfo in
                let coin = marketInfo.fullCoin.coin

                cell(
                    coin: coin,
                    marketCap: marketInfo.marketCap,
                    price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    rank: marketInfo.marketCapRank,
                    diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod),
                    signal: viewModel.showSignals ? signals[coin.uid] : nil,
                    action: {
                        Coordinator.shared.presentCoinPage(coin: coin, page: .markets, section: .watchlist)
                    }
                )
                .swipeActions {
                    Button(role: .destructive) {
                        viewModel.remove(coinUid: coin.uid)
                    } label: {
                        Image("heart_broke_24").renderingMode(.template)
                    }
                    .tint(.themeLucian)
                }
            }
            .environment(\.editMode, $editMode)
            .refreshable {
                await viewModel.refresh()
            }
            .animation(.default, value: editMode)
            .onChange(of: viewModel.sortBy) { _ in
                editMode = .inactive
                withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) }
            }
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
                diff: index % 2 == 0 ? 12.34 : -12.34,
                signal: nil
            )
            .redacted()
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func cell(coin: Coin?, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?, signal: TechnicalAdvice.Advice?, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                CoinIconView(coin: coin)
            },
            middle: {
                MultiText(
                    title: coin?.code ?? "CODE",
                    badge: signal.map { ComponentBadge(text: $0.title, mode: .transparent, colorStyle: $0.colorStyle) },
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
