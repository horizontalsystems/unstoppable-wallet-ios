import CurrencyKit
import SDWebImageSwiftUI
import SwiftUI

struct CoinOverviewView: View {
    @ObservedObject var viewModel: CoinOverviewViewModelNew
    @ObservedObject var chartViewModel: CoinChartViewModel
    let chartIndicatorRepository: IChartIndicatorsRepository
    let chartPointFetcher: IChartPointFetcher

    @State private var hasAppeared = false
    @State private var chartIndicatorsShown = false

    var body: some View {
        ThemeView {
            ZStack {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case let .failed(error):
                    Text(error.localizedDescription)
                case let .completed(item):
                    let info = item.info
                    let coin = item.info.fullCoin.coin
                    let coinCode = coin.code
                    let rank = info.marketCapRank.map { "#\($0)" }

                    ScrollView {
                        VStack(spacing: 0) {
                            HStack(spacing: .margin16) {
                                WebImage(url: URL(string: coin.imageUrl))
                                    .placeholder(Image("placeholder_circle_32"))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: .iconSize32, height: .iconSize32)

                                Text(coin.name).themeBody()

                                if let rank {
                                    Text(rank).themeSubhead1(alignment: .trailing)
                                }
                            }
                            .padding(.horizontal, .margin16)
                            .padding(.vertical, .margin12)

                            ChartView(viewModel: chartViewModel, configuration: .coinChart)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    chartViewModel.start()
                                }

                            VStack {
                                ListSection {
                                    ListRow {
                                        Text("coin_overview.indicators".localized).themeSubhead2()

                                        Button(action: {
                                            chartViewModel.onToggleIndicators()
                                        }) {
                                            Text(chartViewModel.indicatorsShown ? "coin_overview.indicators.hide".localized : "coin_overview.indicators.show".localized)
                                                .animation(.none)
                                        }
                                        .buttonStyle(SecondaryButtonStyle(style: .default))

                                        Button(action: {
                                            chartIndicatorsShown = true
                                        }) {
                                            Image("setting_20").renderingMode(.template)
                                        }
                                        .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                                    }
                                }

                                let infoItems = [
                                    format(value: info.marketCap, currency: viewModel.currency).map {
                                        (title: "coin_overview.market_cap".localized, badge: rank, text: $0)
                                    },
                                    format(value: info.totalSupply, coinCode: coinCode).map {
                                        (title: "coin_overview.total_supply".localized, badge: nil, text: $0)
                                    },
                                    format(value: info.circulatingSupply, coinCode: coinCode).map {
                                        (title: "coin_overview.circulating_supply".localized, badge: nil, text: $0)
                                    },
                                    format(value: info.volume24h, currency: viewModel.currency).map {
                                        (title: "coin_overview.trading_volume".localized, badge: nil, text: $0)
                                    },
                                    format(value: info.dilutedMarketCap, currency: viewModel.currency).map {
                                        (title: "coin_overview.diluted_market_cap".localized, badge: nil, text: $0)
                                    },
                                    info.genesisDate.map {
                                        (title: "coin_overview.genesis_date".localized, badge: nil, text: DateHelper.instance.formatFullDateOnly(from: $0))
                                    },
                                ].compactMap { $0 }

                                if !infoItems.isEmpty {
                                    ListSection {
                                        ForEach(infoItems, id: \.title) { infoItem in
                                            ListRow {
                                                Text(infoItem.title).themeSubhead2()
                                                Text(infoItem.text).themeSubhead1(color: .themeLeah, alignment: .trailing)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            viewModel.sync()
        }
        .sheet(isPresented: $chartIndicatorsShown) {
            ChartIndicatorsModule.view(repository: chartIndicatorRepository, fetcher: chartPointFetcher)
                .ignoresSafeArea()
        }
    }

    private func format(value: Decimal?, coinCode: String) -> String? {
        guard let value = value, !value.isZero else {
            return nil
        }

        return ValueFormatter.instance.formatShort(value: value, decimalCount: 0, symbol: coinCode)
    }

    private func format(value: Decimal?, currency: Currency) -> String? {
        guard let value = value, !value.isZero else {
            return nil
        }

        return ValueFormatter.instance.formatShort(currency: currency, value: value)
    }
}
