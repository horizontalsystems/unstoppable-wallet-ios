import Kingfisher
import MarketKit
import SwiftUI

struct MarketWatchlistView: View {
    @ObservedObject var viewModel: MarketWatchlistViewModel

    @State private var sortBySelectorPresented = false
    @State private var timePeriodSelectorPresented = false
    @State private var presentedFullCoin: FullCoin?
    @State private var signalsPresented = false

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
        .sheet(item: $presentedFullCoin) { fullCoin in
            CoinPageViewNew(coinUid: fullCoin.coin.uid).ignoresSafeArea()
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
            viewItems: WatchlistTimePeriod.allCases.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.timePeriod = WatchlistTimePeriod.allCases[index]
            }
        )
        .sheet(isPresented: $signalsPresented) {
            MarketWatchlistSignalsView(viewModel: viewModel, isPresented: $signalsPresented)
        }
    }

    @ViewBuilder private func signalsButton() -> some View {
        Button(action: {
            if viewModel.showSignals {
                viewModel.showSignals = false
            } else if viewModel.signalsApproved {
                viewModel.showSignals = true
            } else {
                signalsPresented = true
            }
        }) {
            Text("market.watchlist.signals".localized)
        }
    }

    @ViewBuilder private func list(marketInfos: [MarketInfo], signals: [String: TechnicalAdvice.Advice]) -> some View {
        ThemeList(
            items: marketInfos,
            onMove: viewModel.sortBy == .manual ? { source, destination in
                viewModel.move(source: source, destination: destination)
            } : nil
        ) { marketInfo in
            let coin = marketInfo.fullCoin.coin

            ClickableRow(action: {
                presentedFullCoin = marketInfo.fullCoin
            }) {
                itemContent(
                    imageUrl: URL(string: coin.imageUrl),
                    code: coin.code,
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
        .themeListStyle(.transparent)
        .environment(\.editMode, $editMode)
        .refreshable {
            await viewModel.refresh()
        }
        .animation(.default, value: editMode)
        .onChange(of: viewModel.sortBy) { _ in
            editMode = .inactive
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(items: Array(0 ... 10)) { index in
            ListRow {
                itemContent(
                    imageUrl: nil,
                    code: "CODE",
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

    @ViewBuilder private func itemContent(imageUrl: URL?, code: String, marketCap: Decimal?, price: String, rank: Int?, diff: Decimal?, signal: TechnicalAdvice.Advice?) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { Circle().fill(Color.themeSteel20) }
            .clipShape(Circle())
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                HStack(spacing: .margin8) {
                    Text(code).textBody()

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
