import Kingfisher
import MarketKit
import SwiftUI

struct MarketSectorsView: View {
    private let coinCount = 3

    @ObservedObject var viewModel: MarketSectorsViewModel

    @State private var sortBySelectorPresented = false
    @State private var timePeriodSelectorPresented = false

    @State private var presentedSector: CoinCategory?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(sectors):
                VStack(spacing: 0) {
                    header()
                    list(sectors: sectors)
                }
            case .failed:
                SyncErrorView {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .sheet(item: $presentedSector) { sector in
            let isPresented = Binding<Bool>(
                get: { presentedSector != nil },
                set: { newValue in if !newValue { presentedSector = nil }}
            )

            MarketSectorView(isPresented: isPresented, sector: sector).ignoresSafeArea()
                .onFirstAppear { stat(page: .markets, section: .sectors, event: .openSector(sectorUid: sector.uid)) }
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

    @ViewBuilder private func list(sectors: [MarketSectorsViewModel.CoinSectorWithTopCoins]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(sectors, invisibleTopView: true) { sector in
                ClickableRow(action: {
                    presentedSector = sector.sector
                }) {
                    itemContent(
                        coins: sector.topCoins,
                        name: sector.sector.name,
                        marketCap: sector.sector.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                        diff: sector.sector.diff(timePeriod: viewModel.timePeriod)
                    )
                }
            }
            .themeListStyle(.transparent)
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
            .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(themeListTopViewId) } }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { _ in
            ListRow {
                itemContent(
                    coins: [nil, nil, nil],
                    name: "Market Name",
                    marketCap: "12 B",
                    diff: -5.2
                )
                .redacted()
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(coins: [Coin?], name: String, marketCap: String, diff: Decimal?) -> some View {
        ZStack(alignment: .leading) {
            ForEach(Array(coins.prefix(coinCount).reversed().enumerated()), id: \.element) { index, coin in
                icon(coin: coin)
                    .padding(.leading, CGFloat(coinCount - 1 - index) * 22)
            }
        }
        .frame(width: .iconSize32 + CGFloat(coinCount - 1) * 22)

        HStack(spacing: .margin8) {
            Text(name).textBody()
            Spacer()
            VStack(alignment: .trailing, spacing: .heightOneDp) {
                Text(marketCap).textBody()
                DiffText(diff)
            }
        }
    }

    @ViewBuilder private func icon(coin: Coin?) -> some View {
        ZStack {
            Circle()
                .fill(Color.themeTyler)
                .frame(width: .iconSize32, height: .iconSize32)

            if let coin {
                CoinIconView(coin: coin)
            }
        }
    }
}
