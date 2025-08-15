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
            ThemeView(style: .list) {
                switch viewModel.state {
                case .loading:
                    loadingList()
                case let .loaded(defiCoins):
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

                            list(defiCoins: defiCoins)
                        }
                        .onChange(of: viewModel.platforms) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
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
        ListHeader(scrollable: true) {
            DropdownButton(text: viewModel.platforms.title) {
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
            }
            .disabled(disabled)

            ThemeButton(text: "market.tvl_in_defi.tvl".localized, icon: sortIcon, style: .secondary, size: .small) {
                viewModel.sortOrder.toggle()
            }
            .disabled(disabled)

            IconButton(icon: diffIcon, style: .secondary, size: .small) {
                viewModel.diffType.toggle()
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(defiCoins: [DefiCoin]) -> some View {
        Section {
            ListForEach(defiCoins) { defiCoin in
                let platform = defiCoin.chains.count == 1 ? defiCoin.chains[0] : "market.tvl_in_defi.multi_chain".localized
                let values: (Decimal?, Diff?) = viewModel.values(defiCoin: defiCoin)

                switch defiCoin.type {
                case let .defiCoin(name, url):
                    cell(
                        imageUrl: URL(string: url),
                        code: name,
                        platform: platform,
                        rank: defiCoin.tvlRank,
                        tvl: values.0,
                        diff: values.1
                    )
                case let .fullCoin(fullCoin):
                    let coin = fullCoin.coin

                    cell(
                        coin: coin,
                        platform: platform,
                        rank: defiCoin.tvlRank,
                        tvl: values.0,
                        diff: values.1,
                        action: {
                            Coordinator.shared.presentCoinPage(coin: coin, page: .marketTvl)
                        }
                    )
                    .watchlistSwipeActions(viewModel: watchlistViewModel, coinUid: coin.uid)
                }
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
                        imageUrl: nil,
                        code: "CODE",
                        platform: "market.global.tvl_in_defi.multi_chain".localized,
                        rank: 12,
                        tvl: 123_456,
                        diff: .percent(value: index % 2 == 0 ? 12.34 : -12.34)
                    )
                    .redacted()
                }
            } header: {
                listHeader(disabled: true)
            }
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(imageUrl: URL?, code: String, platform: String, rank: Int?, tvl: Decimal?, diff: Diff?, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                KFImage.url(imageUrl)
                    .resizable()
                    .placeholder { Circle().fill(Color.themeBlade) }
                    .clipShape(Circle())
                    .frame(width: .iconSize32, height: .iconSize32)

            },
            middle: {
                MultiText(
                    title: code,
                    subtitleBadge: rank.map { "\($0)" },
                    subtitle: platform
                )
            },
            right: {
                RightMultiText(
                    title: tvl.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
                    subtitle: Diff.text(diff: diff)
                )
            },
            action: action
        )
    }

    @ViewBuilder private func cell(coin: Coin?, platform: String, rank: Int?, tvl: Decimal?, diff: Diff?, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                CoinIconView(coin: coin)
            },
            middle: {
                MultiText(
                    title: coin?.code ?? "CODE",
                    subtitleBadge: rank.map { "\($0)" },
                    subtitle: platform
                )
            },
            right: {
                RightMultiText(
                    title: tvl.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) },
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

    private var diffIcon: String {
        switch viewModel.diffType {
        case .percent: return "percent"
        case .currencyValue: return "usd"
        }
    }
}
