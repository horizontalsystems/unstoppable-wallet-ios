import Kingfisher
import MarketKit
import SwiftUI

struct MarketWatchlistView: View {
    @ObservedObject var viewModel: MarketWatchlistViewModel

    @State private var sortBySelectorPresented = false
    @State private var timePeriodSelectorPresented = false

    @State private var presentedFullCoin: FullCoin?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(marketInfos, signals):
                if marketInfos.isEmpty {
                    PlaceholderViewNew(image: Image("rate_48"), text: "market.watchlist.empty".localized)
                } else {
                    VStack(spacing: 0) {
                        header()
                        list(marketInfos: marketInfos, signals: signals)
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

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    sortBySelectorPresented = true
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
                    timePeriodSelectorPresented = true
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                if viewModel.showSignals {
                    signalsButton()
                        .buttonStyle(SecondaryActiveButtonStyle())
                        .disabled(disabled)
                } else {
                    signalsButton()
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(disabled)
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
            isPresented: $timePeriodSelectorPresented,
            title: "market.time_period.title".localized,
            viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.timePeriod = viewModel.timePeriods[index]
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

    @ViewBuilder private func list(marketInfos: [MarketInfo], signals: [String: TechnicalAdvice.Advice]) -> some View {
        ThemeList(items: marketInfos) { marketInfo in
            let coin = marketInfo.fullCoin.coin

            ClickableRow(action: {
                presentedFullCoin = marketInfo.fullCoin
            }) {
                itemContent(
                    imageUrl: URL(string: coin.imageUrl),
                    code: coin.code,
                    name: coin.name,
                    price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    rank: marketInfo.marketCapRank,
                    diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod),
                    signal: viewModel.showSignals ? signals[coin.uid] : nil
                )
            }
            .swipeActions {
                Button(role: .destructive) {
                    viewModel.remove(coinUid: coin.uid)
                } label: {
                    Image("star_off_24").renderingMode(.template)
                }
                .tint(.themeLucian)
            }
        }
        .themeListStyle(.transparent)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(items: Array(0 ... 10)) { index in
            ListRow {
                itemContent(
                    imageUrl: nil,
                    code: "CODE",
                    name: "Coin Name",
                    price: "$123.45",
                    rank: 12,
                    diff: index % 2 == 0 ? 12.34 : -12.34,
                    signal: nil
                )
                .redacted()
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(imageUrl: URL?, code: String, name: String, price: String, rank: Int?, diff: Decimal?, signal: TechnicalAdvice.Advice?) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { Circle().fill(Color.themeSteel20) }
            .clipShape(Circle())
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                HStack(spacing: .margin12) {
                    Text(code).textBody()

                    if let signal {
                        Text(signal.title)
                            .font(.themeMicroSB)
                            .foregroundColor(.themeTyler)
                            .padding(.horizontal, .margin4)
                            .padding(.vertical, .margin2)
                            .background(RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous).fill(color(signal: signal)))
                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous))
                    }
                }

                Spacer()
                Text(price).textBody()
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    if let rank {
                        BadgeViewNew(text: "\(rank)")
                    }

                    Text(name).textSubhead2()
                }
                Spacer()
                DiffText(diff)
            }
        }
    }

    private func color(signal: TechnicalAdvice.Advice) -> Color {
        switch signal {
        case .oversold, .overbought: return .themeLucian
        case .strongSell, .strongBuy: return .themeRemus
        case .sell, .buy: return .themeStronbuy
        case .neutral: return .themeLeah
        }
    }
}
