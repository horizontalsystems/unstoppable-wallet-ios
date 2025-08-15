import Kingfisher
import MarketKit
import SwiftUI

struct MarketPairsView: View {
    @ObservedObject var viewModel: MarketPairsViewModel

    var body: some View {
        ThemeView(style: .list) {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(pairs):
                VStack(spacing: 0) {
                    header()
                    list(pairs: pairs)
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
            DropdownButton(text: "market.pairs.volume".localized) {
                viewModel.volumeSortOrder.toggle()
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(pairs: [MarketPair]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(pairs) { pair in
                cell(
                    baseCoin: pair.baseCoin,
                    targetCoin: pair.targetCoin,
                    base: pair.base,
                    target: pair.target,
                    volume: pair.volume.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    marketName: pair.marketName,
                    rank: pair.rank,
                    price: pair.price.flatMap { ValueFormatter.instance.formatShort(value: $0, decimalCount: 8, symbol: pair.target) } ?? "n/a".localized,
                    action: {
                        if let tradeUrl = pair.tradeUrl {
                            UrlManager.open(url: tradeUrl)
                            stat(page: .markets, section: .pairs, event: .open(page: .externalMarketPair))
                        }
                    }
                )
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: viewModel.volumeSortOrder) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { _ in
            cell(
                baseCoin: nil,
                targetCoin: nil,
                base: "CODE",
                target: "CODE",
                volume: "$123.4 B",
                marketName: "Market Name",
                rank: 12,
                price: "123 CODE"
            )
            .redacted()
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(baseCoin: Coin?, targetCoin: Coin?, base: String, target: String, volume: String, marketName: String, rank: Int, price: String, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                ZStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        icon(coin: targetCoin, ticker: target)
                    }

                    icon(coin: baseCoin, ticker: base)
                }
                .frame(width: 52)

            },
            middle: {
                MultiText(
                    title: "\(base) / \(target)",
                    subtitleBadge: "\(rank)",
                    subtitle: marketName
                )
            },
            right: {
                RightMultiText(
                    title: volume,
                    subtitle: price
                )
            },
            action: action
        )
    }

    @ViewBuilder private func icon(coin: Coin?, ticker: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.themeTyler)
                .frame(width: .iconSize32, height: .iconSize32)

            if let coin {
                CoinIconView(coin: coin)
            } else {
                KFImage.url(URL(string: ticker.fiatImageUrl))
                    .resizable()
                    .placeholder { Circle().fill(Color.themeBlade) }
                    .clipShape(Circle())
                    .frame(width: .iconSize32, height: .iconSize32)
            }
        }
    }

    private func volumeSortIcon() -> Image {
        switch viewModel.volumeSortOrder {
        case .asc: return Image("arrow_medium_2_up_20")
        case .desc: return Image("arrow_medium_2_down_20")
        }
    }
}
