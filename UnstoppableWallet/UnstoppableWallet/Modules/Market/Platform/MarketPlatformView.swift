import Kingfisher
import MarketKit
import SwiftUI

struct MarketPlatformView: View {
    @StateObject var viewModel: MarketPlatformViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>, platform: TopPlatform) {
        _viewModel = StateObject(wrappedValue: MarketPlatformViewModel(platform: platform))
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.platformInstance(platform: platform))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .topPlatform))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView(style: .list) {
                switch viewModel.state {
                case .loading:
                    loadingList()
                case let .loaded(marketInfos):
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16) {
                            chart()
                                .listRowBackground(Color.themeTyler)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .themeListTopView()

                            list(marketInfos: marketInfos)
                        }
                        .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                        .themeListScrollHeader()
                    }
                case .failed:
                    SyncErrorView {
                        viewModel.sync()
                    }
                }
            }
            .navigationTitle("top_platform.title".localized(viewModel.platform.blockchain.name))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func chart() -> some View {
        ChartView(viewModel: chartViewModel, configuration: .marketCapChart)
            .frame(maxWidth: .infinity)
            .onFirstAppear {
                chartViewModel.start()
            }
    }

    @ViewBuilder private func listHeader(disabled: Bool = false) -> some View {
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
        Section {
            ListForEach(marketInfos) { marketInfo in
                let coin = marketInfo.fullCoin.coin

                cell(
                    coin: coin,
                    marketCap: marketInfo.marketCap,
                    price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    rank: marketInfo.marketCapRank,
                    diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod),
                    action: {
                        Coordinator.shared.presentCoinPage(coin: coin, page: .globalMetricsTvlInDefi)
                    }
                )
                .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
            }
        } header: {
            listHeader()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(bottomSpacing: .margin16) {
            ZStack {
                ProgressView()
            }
            .frame(height: 277) // TODO: use real chart height (after migrating to Swift Charts)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.themeTyler)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)

            Section {
                ListForEach(Array(0 ... 10)) { index in
                    cell(
                        coin: nil,
                        marketCap: 123_456,
                        price: "$123.45",
                        rank: 12,
                        diff: index % 2 == 0 ? 12.34 : -12.34
                    )
                    .redacted()
                }
            } header: {
                listHeader(disabled: true)
            }
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
