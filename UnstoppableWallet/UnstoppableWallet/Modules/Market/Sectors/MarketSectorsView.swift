import Kingfisher
import MarketKit
import SwiftUI

struct MarketSectorsView: View {
    private let coinCount = 3

    @ObservedObject var viewModel: MarketSectorsViewModel

    var body: some View {
        ThemeView(style: .list) {
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
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ListHeader(scrollable: true) {
            DropdownButton(text: viewModel.sortBy.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.sort_by.title".localized,
                        viewItems: viewModel.sortBys.map { .init(text: $0.title, selected: viewModel.sortBy == $0) },
                        onSelect: { index in
                            viewModel.sortBy = viewModel.sortBys[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)

            DropdownButton(text: viewModel.timePeriod.shortTitle) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "market.time_period.title".localized,
                        viewItems: viewModel.timePeriods.map { .init(text: $0.title, selected: viewModel.timePeriod == $0) },
                        onSelect: { index in
                            viewModel.timePeriod = viewModel.timePeriods[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(sectors: [MarketSectorsViewModel.CoinSectorWithTopCoins]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(sectors) { sector in
                cell(
                    coins: sector.topCoins,
                    name: sector.sector.name,
                    marketCap: sector.sector.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    diff: sector.sector.diff(timePeriod: viewModel.timePeriod),
                    action: {
                        Coordinator.shared.present { isPresented in
                            MarketSectorView(isPresented: isPresented, sector: sector.sector).ignoresSafeArea()
                        }

                        stat(page: .markets, section: .sectors, event: .openSector(sectorUid: sector.sector.uid))
                    }
                )
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
            .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { _ in
            cell(
                coins: [nil, nil, nil],
                name: "Market Name",
                marketCap: "12 B",
                diff: -5.2
            )
            .redacted()
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(coins: [Coin?], name: String, marketCap: String, diff: Decimal?, action: (() -> Void)? = nil) -> some View {
        let coins = Array(coins.prefix(coinCount).reversed())

        Cell(
            left: {
                ZStack(alignment: .leading) {
                    ForEach(coins.indices, id: \.self) { index in
                        icon(coin: coins[index])
                            .padding(.leading, CGFloat(coinCount - 1 - index) * 22)
                    }
                }
                .frame(width: .iconSize32 + CGFloat(coinCount - 1) * 22)
            },
            middle: {
                MultiText(title: name)
            },
            right: {
                RightMultiText(
                    title: marketCap,
                    subtitle: Diff.text(diff: diff)
                )
            },
            action: action
        )
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
