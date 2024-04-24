import Kingfisher
import MarketKit
import SwiftUI

struct MarketCoinsView: View {
    @ObservedObject var viewModel: MarketCoinsViewModel

    @State private var sortBySelectorPresented = false
    @State private var topSelectorPresented = false
    @State private var priceChangePeriodSelectorPresented = false

    @State private var presentedFullCoin: FullCoin?

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(action: {
                            sortBySelectorPresented = true
                        }) {
                            Text(viewModel.sortBy.title)
                        }
                        .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))

                        Button(action: {
                            topSelectorPresented = true
                        }) {
                            Text(viewModel.top.title)
                        }
                        .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))

                        Button(action: {
                            priceChangePeriodSelectorPresented = true
                        }) {
                            Text(viewModel.priceChangePeriod.shortTitle)
                        }
                        .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                    }
                    .padding(.horizontal, .margin16)
                    .padding(.vertical, .margin8)
                }
                .alert(
                    isPresented: $sortBySelectorPresented,
                    title: "market.sort_by.title".localized,
                    viewItems: MarketModule.SortBy.allCases.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
                    onTap: { index in
                        guard let index else {
                            return
                        }

                        viewModel.sortBy = MarketModule.SortBy.allCases[index]
                    }
                )
                .alert(
                    isPresented: $topSelectorPresented,
                    title: "market.top_coins.title".localized,
                    viewItems: viewModel.tops.map { .init(text: $0.title, selected: viewModel.top == $0) },
                    onTap: { index in
                        guard let index else {
                            return
                        }

                        viewModel.top = viewModel.tops[index]
                    }
                )
                .alert(
                    isPresented: $priceChangePeriodSelectorPresented,
                    title: "market.price_change_period.title".localized,
                    viewItems: viewModel.priceChangePeriods.map { .init(text: $0.shortTitle, selected: viewModel.priceChangePeriod == $0) },
                    onTap: { index in
                        guard let index else {
                            return
                        }

                        viewModel.priceChangePeriod = viewModel.priceChangePeriods[index]
                    }
                )

                ZStack {
                    switch viewModel.state {
                    case .loading:
                        ProgressView()
                    case let .loaded(marketInfos):
                        list(marketInfos: marketInfos)
                    case .failed:
                        SyncErrorView {
                            // viewModel.onRetry()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .sheet(item: $presentedFullCoin) { fullCoin in
            CoinPageViewNew(coinUid: fullCoin.coin.uid)
        }
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo]) -> some View {
        ScrollViewReader { _ in
            ThemeList(items: marketInfos) { marketInfo in
                ClickableRow(action: {
                    presentedFullCoin = marketInfo.fullCoin
                }) {
                    let coin = marketInfo.fullCoin.coin

                    KFImage.url(URL(string: coin.imageUrl))
                        .resizable()
                        .placeholder { Circle().fill(Color.themeSteel20) }
                        .frame(width: .iconSize32, height: .iconSize32)

                    VStack(spacing: 1) {
                        HStack(spacing: .margin8) {
                            Text(coin.code).textBody()
                            Spacer()
                            Text(marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized).textBody()
                        }

                        HStack(spacing: .margin8) {
                            HStack(spacing: .margin4) {
                                if let rank = marketInfo.marketCapRank {
                                    BadgeViewNew(text: "\(rank)")
                                }

                                Text(coin.name).textSubhead2()
                            }
                            Spacer()
                            DiffText(marketInfo.priceChangeValue(period: viewModel.priceChangePeriod))
                        }
                    }
                }
            }
            .themeListStyle(.transparent)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}
