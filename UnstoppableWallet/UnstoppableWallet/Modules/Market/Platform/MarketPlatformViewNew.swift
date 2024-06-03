import Kingfisher
import MarketKit
import SwiftUI

struct MarketPlatformViewNew: View {
    @StateObject var viewModel: MarketPlatformViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isPresented: Bool

    @State private var sortBySelectorPresented = false
    @State private var presentedFullCoin: FullCoin?

    init(isPresented: Binding<Bool>, platform: TopPlatform) {
        _viewModel = StateObject(wrappedValue: MarketPlatformViewModel(platform: platform))
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.platformInstance(platform: platform))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .topPlatform))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                switch viewModel.state {
                case .loading:
                    VStack(spacing: 0) {
                        header()
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case let .loaded(marketInfos):
                    ThemeList(bottomSpacing: .margin16) {
                        header()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        chart()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)

                        list(marketInfos: marketInfos)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }
            }
            .sheet(item: $presentedFullCoin) { fullCoin in
                CoinPageViewNew(coinUid: fullCoin.coin.uid).ignoresSafeArea()
                    .onFirstAppear { stat(page: .globalMetricsTvlInDefi, event: .openCoin(coinUid: fullCoin.coin.uid)) }
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        HStack(spacing: .margin32) {
            VStack(spacing: .margin8) {
                Text("top_platform.title".localized(viewModel.platform.blockchain.name)).themeHeadline1()
                Text("top_platform.description".localized(viewModel.platform.blockchain.name)).themeSubhead2()
            }
            .padding(.vertical, .margin12)

            KFImage.url(URL(string: viewModel.platform.blockchain.type.imageUrl))
                .resizable()
                .frame(width: .iconSize32, height: .iconSize32)
        }
        .padding(.leading, .margin16)
        .padding(.trailing, .margin16)
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
                    sortBySelectorPresented = true
                }) {
                    Text(viewModel.sortBy.title)
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
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo]) -> some View {
        Section {
            ListForEach(marketInfos) { marketInfo in
                let coin = marketInfo.fullCoin.coin

                ClickableRow(action: {
                    presentedFullCoin = marketInfo.fullCoin
                }) {
                    itemContent(
                        coin: coin,
                        marketCap: marketInfo.marketCap,
                        price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                        rank: marketInfo.marketCapRank,
                        diff: marketInfo.priceChange24h
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
