import Kingfisher
import MarketKit
import SwiftUI

struct MarketTvlView: View {
    @StateObject var viewModel: MarketTvlViewModel
    @StateObject var chartViewModel: MetricChartViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel

    @Environment(\.presentationMode) private var presentationMode

    init() {
        _viewModel = StateObject(wrappedValue: MarketTvlViewModel())
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.instance(type: .tvlInDefi))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .globalMetricsTvlInDefi))
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                switch viewModel.state {
                case .loading:
                    VStack(spacing: 0) {
                        header()
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case let .loaded(defiCoins):
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16) {
                            header()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            chart()
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            list(defiCoins: defiCoins)
                        }
                        .onChange(of: viewModel.platforms) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                        .onChange(of: viewModel.sortOrder) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
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
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onReceive(chartViewModel.$periodType) { periodType in
                viewModel.timePeriod = HsTimePeriod(periodType) ?? .day1
            }
        }
    }

    @ViewBuilder private func header() -> some View {
        HStack(spacing: .margin32) {
            VStack(spacing: .margin8) {
                Text("market.tvl_in_defi.title".localized).themeHeadline1()
                Text("market.tvl_in_defi.description".localized).themeSubhead2()
            }
            .padding(.vertical, .margin12)

            KFImage.url(URL(string: "tvl".headerImageUrl))
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "market.tvl_in_defi.filter_by_chain".localized,
                            viewItems: MarketTvlViewModel.Platforms.allCases.map { .init(text: $0.title, selected: viewModel.platforms == $0) },
                            onSelect: { index in
                                viewModel.platforms = MarketTvlViewModel.Platforms.allCases[index]
                            },
                            isPresented: isPresented
                        )
                    }
                }) {
                    Text(viewModel.platforms.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    viewModel.sortOrder.toggle()
                }) {
                    Text("market.tvl_in_defi.tvl".localized)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .custom(image: sortIcon())))

                Button(action: {
                    viewModel.diffType.toggle()
                }) {
                    diffIcon().themeIcon(color: .themeLeah)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
    }

    @ViewBuilder private func list(defiCoins: [DefiCoin]) -> some View {
        Section {
            ListForEach(defiCoins) { defiCoin in
                let platform = defiCoin.chains.count == 1 ? defiCoin.chains[0] : "market.tvl_in_defi.multi_chain".localized
                let values: (Decimal?, DiffText.Diff?) = viewModel.values(defiCoin: defiCoin)

                switch defiCoin.type {
                case let .defiCoin(name, url):
                    ListRow {
                        itemContent(
                            imageUrl: URL(string: url),
                            code: name,
                            platform: platform,
                            rank: defiCoin.tvlRank,
                            tvl: values.0,
                            diff: values.1
                        )
                    }
                case let .fullCoin(fullCoin):
                    let coin = fullCoin.coin

                    ClickableRow(action: {
                        Coordinator.shared.presentCoinPage(coin: coin, page: .marketTvl)
                    }) {
                        itemContent(
                            coin: coin,
                            platform: platform,
                            rank: defiCoin.tvlRank,
                            tvl: values.0,
                            diff: values.1
                        )
                    }
                    .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
                }
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
                        imageUrl: nil,
                        code: "CODE",
                        platform: "market.global.tvl_in_defi.multi_chain".localized,
                        rank: 12,
                        tvl: 123_456,
                        diff: .percent(value: index % 2 == 0 ? 12.34 : -12.34)
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

    @ViewBuilder private func itemContent(imageUrl: URL?, code: String, platform: String, rank: Int?, tvl: Decimal?, diff: DiffText.Diff?) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { Circle().fill(Color.themeBlade) }
            .clipShape(Circle())
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(code).textBody()
                Spacer()
                if let tvl, let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: tvl) {
                    Text(formatted).textBody()
                }
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    if let rank {
                        BadgeViewNew(text: "\(rank)")
                    }
                    Text(platform).textSubhead2()
                }
                Spacer()
                DiffText(diff)
            }
        }
    }

    @ViewBuilder private func itemContent(coin: Coin?, platform: String, rank: Int?, tvl: Decimal?, diff: DiffText.Diff?) -> some View {
        CoinIconView(coin: coin)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(coin?.code ?? "CODE").textBody()
                Spacer()
                if let tvl, let formatted = ValueFormatter.instance.formatShort(currency: viewModel.currency, value: tvl) {
                    Text(formatted).textBody()
                }
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    if let rank {
                        BadgeViewNew(text: "\(rank)")
                    }
                    Text(platform).textSubhead2()
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

    private func diffIcon() -> Image {
        switch viewModel.diffType {
        case .percent: return Image("percent_20")
        case .currencyValue: return Image("usd_20")
        }
    }
}
