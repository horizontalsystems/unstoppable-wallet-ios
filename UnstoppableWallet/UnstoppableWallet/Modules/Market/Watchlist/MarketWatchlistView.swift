import Kingfisher
import MarketKit
import SwiftUI

struct MarketWatchlistView: View {
    @ObservedObject var viewModel: MarketWatchlistViewModel

    @State private var sortBySelectorPresented = false
    @State private var priceChangePeriodSelectorPresented = false

    @State private var presentedFullCoin: FullCoin?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                loadingList()
            case let .loaded(marketInfos):
                if marketInfos.isEmpty {
                    PlaceholderViewNew(image: Image("rate_48"), text: "market.watchlist.empty".localized)
                } else {
                    VStack(spacing: 0) {
                        header()
                        list(marketInfos: marketInfos)
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
        .sheet(item: $presentedFullCoin) { fullCoin in
            CoinPageViewNew(coinUid: fullCoin.coin.uid)
        }
    }

    @ViewBuilder private func header() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    sortBySelectorPresented = true
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))

                Button(action: {
                    priceChangePeriodSelectorPresented = true
                }) {
                    Text(viewModel.priceChangePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))

                if viewModel.showSignals {
                    signalsButton().buttonStyle(SecondaryActiveButtonStyle())
                } else {
                    signalsButton().buttonStyle(SecondaryButtonStyle())
                }
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
    }

    @ViewBuilder private func signalsButton() -> some View {
        Button(action: {
            viewModel.showSignals.toggle()
        }) {
            Text("market.watchlist.signals".localized)
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

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(items: Array(0 ... 10)) { _ in
            ListRow {
                Circle()
                    .fill(Color.themeSteel20)
                    .frame(width: .iconSize32, height: .iconSize32)
                    .shimmering()

                VStack(spacing: 1) {
                    HStack(spacing: .margin8) {
                        Text("USDT").textBody().redacted(value: nil)
                        Spacer()
                        Text("$12345").textBody().redacted(value: nil)
                    }

                    HStack(spacing: .margin8) {
                        HStack(spacing: .margin4) {
                            Text("12").textBody().redacted(value: nil)
                            Text("Bitcoin").textSubhead2().redacted(value: nil)
                        }
                        Spacer()
                        DiffText(12.34).redacted(value: nil)
                    }
                }
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }
}
