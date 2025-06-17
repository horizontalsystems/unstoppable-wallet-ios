import Kingfisher
import MarketKit
import SwiftUI

struct MarketAdvancedSearchResultsView: View {
    @StateObject var viewModel: MarketAdvancedSearchResultsViewModel
    @StateObject var watchlistViewModel: WatchlistViewModel
    @Binding var isParentPresented: Bool

    @State private var sortBySelectorPresented = false
    @State private var presentedCoin: Coin?
    @State private var signalsPresented = false
    @State private var subscriptionPresented = false

    init(marketInfos: [MarketInfo], timePeriod: HsTimePeriod, isParentPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MarketAdvancedSearchResultsViewModel(marketInfos: marketInfos, timePeriod: timePeriod))
        _watchlistViewModel = StateObject(wrappedValue: WatchlistViewModel(page: .advancedSearchResults))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                header()

                ScrollViewReader { proxy in
                    ThemeList(viewModel.marketInfos, bottomSpacing: .margin16) { marketInfo in
                        let coin = marketInfo.fullCoin.coin

                        ClickableRow(action: {
                            presentedCoin = coin
                        }) {
                            itemContent(
                                coin: coin,
                                indicatorResult: marketInfo.indicatorsResult,
                                marketCap: marketInfo.marketCap,
                                price: marketInfo.price.flatMap { ValueFormatter.instance.formatFull(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                                rank: marketInfo.marketCapRank,
                                diff: marketInfo.priceChangeValue(timePeriod: viewModel.timePeriod)
                            )
                        }
                    }
                    .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                }
            }
        }
        .navigationTitle("market.advanced_search_results.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.close".localized) {
                    isParentPresented = false
                }
            }
        }
        .sheet(item: $presentedCoin) { coin in
            CoinPageView(coin: coin).ignoresSafeArea()
                .onFirstAppear { stat(page: .advancedSearchResults, event: .openCoin(coinUid: coin.uid)) }
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
        .sheet(isPresented: $signalsPresented) {
            MarketWatchlistSignalsView(setShowSignals: { [weak viewModel] in
                viewModel?.set(showSignals: $0)
            }, isPresented: $signalsPresented)
        }
        .sheet(isPresented: $subscriptionPresented) {
            PurchasesView()
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

                if viewModel.showSignals {
                    signalsButton()
                        .buttonStyle(SecondaryActiveButtonStyle(leftAccessory:
                            .custom(icon: "star_premium_20", enabledColor: .themeDark, disabledColor: .themeDark)
                        ))
                } else {
                    signalsButton()
                        .buttonStyle(
                            SecondaryButtonStyle(leftAccessory:
                                .custom(image: Image("star_premium_20"), pressedColor: .themeJacob, activeColor: .themeJacob, disabledColor: .themeJacob)
                            ))
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
    }

    @ViewBuilder private func signalsButton() -> some View {
        Button(action: {
            guard viewModel.premiumEnabled else {
                stat(page: .advancedSearchResults, event: .openPremium(from: .tradingSignal))
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

    @ViewBuilder private func itemContent(coin: Coin?, indicatorResult: TechnicalAdvice.Advice?, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?) -> some View {
        CoinIconView(coin: coin)

        HStack(spacing: .margin16) {
            VStack(spacing: 1) {
                HStack(spacing: .margin8) {
                    Text(coin?.code ?? "CODE").textBody()

                    if viewModel.showSignals, let signal = indicatorResult {
                        MarketWatchlistSignalBadge(signal: signal)
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
            if let coin {
                WatchlistView.watchButton(viewModel: watchlistViewModel, coinUid: coin.uid)
            }
        }
    }
}
