import Kingfisher
import MarketKit
import SwiftUI

struct MarketWatchlistView: View {
    @ObservedObject var viewModel: MarketWatchlistViewModel

    @State private var sortBySelectorPresented = false
    @State private var timePeriodSelectorPresented = false
    @State private var presentedCoin: Coin?
    @State private var signalsPresented = false
    @State private var subscriptionPresented = false

    @State private var editMode: EditMode = .inactive

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
        .sheet(item: $presentedCoin) { coin in
            CoinPageView(coin: coin)
                .onFirstAppear { stat(page: .markets, section: .watchlist, event: .openCoin(coinUid: coin.uid)) }
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

                if viewModel.sortBy == .manual {
                    Button(action: {
                        if editMode == .active {
                            editMode = .inactive
                        } else {
                            editMode = .active
                        }
                    }) {
                        Image("edit2_20").renderingMode(.template)
                    }
                    .buttonStyle(SecondaryCircleButtonStyle(style: .default, isActive: editMode == .active))
                    .disabled(disabled)
                }

                Button(action: {
                    timePeriodSelectorPresented = true
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                if viewModel.showSignals {
                    signalsButton()
                        .buttonStyle(SecondaryActiveButtonStyle(leftAccessory:
                            .custom(icon: "crown_20", enabledColor: .themeDark, disabledColor: .themeDark)
                        ))
                        .disabled(disabled)
                } else {
                    signalsButton()
                        .buttonStyle(
                            SecondaryButtonStyle(leftAccessory:
                                .custom(image: Image("crown_20"), pressedColor: .themeJacob, activeColor: .themeJacob, disabledColor: .themeJacob)
                            ))
                        .disabled(disabled)
                }
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
        .alert(
            isPresented: $sortBySelectorPresented,
            title: "market.sort_by.title".localized,
            viewItems: WatchlistSortBy.allCases.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.sortBy = WatchlistSortBy.allCases[index]
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
        .sheet(isPresented: $signalsPresented) {
            MarketWatchlistSignalsView(setShowSignals: { [weak viewModel] in
                viewModel?.set(showSignals: $0)
            }, isPresented: $signalsPresented)
        }
        .sheet(isPresented: $subscriptionPresented) {
            PurchasesView()
        }
    }

    @ViewBuilder private func signalsButton() -> some View {
        Button(action: {
            guard viewModel.tradeSignalsEnabled else {
                subscriptionPresented = true
                return
            }

            if viewModel.showSignals {
                viewModel.set(showSignals: false)
            } else {
                signalsPresented = true
            }
        }) {
            Text("market.watchlist.signals".localized)
        }
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo], signals: [String: TechnicalAdvice.Advice]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(
                marketInfos,
                invisibleTopView: true,
                onMove: viewModel.sortBy == .manual ? { source, destination in
                    viewModel.move(source: source, destination: destination)
                } : nil
            ) { marketInfo in
                let coin = marketInfo.fullCoin.coin

                ClickableRow(action: {
                    presentedCoin = coin
                }) {
                    itemContent(
                        coin: coin,
                        marketCap: marketInfo.marketCap,
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
            .environment(\.editMode, $editMode)
            .refreshable {
                await viewModel.refresh()
            }
            .animation(.default, value: editMode)
            .onChange(of: viewModel.sortBy) { _ in
                editMode = .inactive
                withAnimation { proxy.scrollTo(themeListTopViewId) }
            }
            .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { index in
            ListRow {
                itemContent(
                    coin: nil,
                    marketCap: 123_456,
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

    @ViewBuilder private func itemContent(coin: Coin?, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?, signal: TechnicalAdvice.Advice?) -> some View {
        CoinIconView(coin: coin)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                HStack(spacing: .margin8) {
                    Text(coin?.code ?? "CODE").textBody()

                    if let signal {
                        MarketWatchlistSignalBadge(signal: signal)
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
