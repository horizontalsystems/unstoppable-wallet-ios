import Kingfisher
import MarketKit
import SwiftUI

struct MarketPlatformViewNew: View {
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
            ThemeView {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case let .loaded(marketInfos):
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16) {
                            chart()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            list(marketInfos: marketInfos)
                        }
                        .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                    }
                case .failed:
                    SyncErrorView {
                        viewModel.sync()
                    }
                }
            }
            .navigationTitle("top_platform.title".localized(viewModel.platform.blockchain.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
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
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
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
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo]) -> some View {
        Section {
            ListForEach(marketInfos) { marketInfo in
                let coin = marketInfo.fullCoin.coin

                ClickableRow(action: {
                    Coordinator.shared.presentCoinPage(coin: coin, page: .globalMetricsTvlInDefi)
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
        } header: {
            listHeader()
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        Section {
            ListForEach(Array(0 ... 10)) { index in
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
        } header: {
            listHeader(disabled: true)
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
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
                        BadgeViewNew("\(rank)")
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
