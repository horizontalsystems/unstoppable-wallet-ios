import Charts
import Kingfisher
import MarketKit
import SwiftUI

struct MarketMarketCapView: View {
    @StateObject var viewModel: MarketMarketCapViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketMarketCapViewModel())
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.instance(type: .totalMarketCap))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .globalMetricsMarketCap))
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
                            header()
                                .listRowBackground(Color.themeTyler)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .themeListTopView()

                            chart()
                                .listRowBackground(Color.themeTyler)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            list(marketInfos: marketInfos)
                        }
                        .onChange(of: viewModel.sortOrder) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                        .themeListScrollHeader()
                    }
                case .failed:
                    VStack(spacing: 0) {
                        header()

                        SyncErrorView {
                            viewModel.sync()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        HStack(spacing: .margin32) {
            VStack(spacing: .margin8) {
                Text("market.market_cap.title".localized).themeHeadline1()
                Text("market.market_cap.description".localized).themeSubhead2()
            }
            .padding(.vertical, .margin12)

            KFImage.url(URL(string: "total_mcap".headerImageUrl))
                .resizable()
                .frame(width: 76, height: 108)
        }
        .padding(.leading, .margin16)
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
            ThemeButton(text: "market.market_cap.market_cap".localized, icon: sortIcon, style: .secondary, size: .small) {
                viewModel.sortOrder.toggle()
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
                    diff: marketInfo.priceChangeValue(timePeriod: HsTimePeriod.day1),
                    action: {
                        Coordinator.shared.presentCoinPage(coin: coin, page: .globalMetricsMarketCap)
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
            header()
                .listRowBackground(Color.themeTyler)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

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

    private var sortIcon: String {
        switch viewModel.sortOrder {
        case .asc: return "arrow_m_up"
        case .desc: return "arrow_m_down"
        }
    }
}
