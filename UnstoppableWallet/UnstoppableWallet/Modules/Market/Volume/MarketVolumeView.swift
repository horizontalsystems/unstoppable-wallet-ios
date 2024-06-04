import Kingfisher
import MarketKit
import SwiftUI

struct MarketVolumeView: View {
    @StateObject var viewModel: MarketVolumeViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isPresented: Bool

    @State private var presentedFullCoin: FullCoin?

    init(isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketVolumeViewModel())
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.instance(type: .volume24h))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .globalMetricsVolume))
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
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16, invisibleTopView: true) {
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
                        .onChange(of: viewModel.sortOrder) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
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
                    .onFirstAppear { stat(page: .globalMetricsVolume, event: .openCoin(coinUid: fullCoin.coin.uid)) }
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        HStack(spacing: .margin32) {
            VStack(spacing: .margin8) {
                Text("market.volume.title".localized).themeHeadline1()
                Text("market.volume.description".localized).themeSubhead2()
            }
            .padding(.vertical, .margin12)

            KFImage.url(URL(string: "total_volume".headerImageUrl))
                .resizable()
                .frame(width: 76, height: 108)
        }
        .padding(.leading, .margin16)
    }

    @ViewBuilder private func chart() -> some View {
        ChartView(viewModel: chartViewModel, configuration: .baseChart)
            .frame(maxWidth: .infinity)
            .onFirstAppear {
                chartViewModel.start()
            }
    }

    @ViewBuilder private func listHeader(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    viewModel.sortOrder.toggle()
                }) {
                    Text("market.volume.volume".localized)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .custom(image: sortIcon())))
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
                    presentedFullCoin = marketInfo.fullCoin
                }) {
                    itemContent(
                        coin: coin,
                        volume: marketInfo.totalVolume,
                        price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                        rank: marketInfo.marketCapRank,
                        diff: marketInfo.priceChangeValue(timePeriod: HsTimePeriod.day1)
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
                        volume: 123_456,
                        price: "$123.45",
                        rank: 12,
                        diff: index % 2 == 0 ? 12.34 : -12.34
                    )
                    .redacted()
                }
            }
        } header: {
            listHeader(disabled: true)
                .listRowInsets(EdgeInsets())
                .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func itemContent(coin: Coin?, volume: Decimal?, price: String, rank: Int?, diff: Decimal?) -> some View {
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

                    if let volume, let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: volume) {
                        Text(formatted).textSubhead2()
                    }
                }
                Spacer()
                DiffText(diff)
            }
        }
    }

    private func sortIcon() -> Image {
        switch viewModel.sortOrder {
        case .asc: return Image("arrow_medium_2_up_20")
        case .desc: return Image("arrow_medium_2_down_20")
        }
    }
}
