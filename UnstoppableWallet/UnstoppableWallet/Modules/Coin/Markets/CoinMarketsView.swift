import Kingfisher
import MarketKit
import SwiftUI

struct CoinMarketsView: View {
    @ObservedObject var viewModel: CoinMarketsViewModel

    var body: some View {
        ThemeView(style: .list) {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(viewItems):
                VStack(spacing: 0) {
                    header()

                    if viewItems.isEmpty {
                        PlaceholderViewNew(image: Image("no_data_48"), text: "coin_markets.empty".localized)
                    } else {
                        list(viewItems: viewItems)
                    }
                }
            case .failed:
                SyncErrorView {
                    viewModel.onRetry()
                }
            }
        }
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ListHeader(scrollable: true) {
            DropdownButton(text: viewModel.marketTypeFilter.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: viewModel.marketTypeFilter.title,
                        viewItems: viewModel.marketTypeFilters.map { .init(text: $0.title, selected: viewModel.marketTypeFilter == $0) },
                        onSelect: { index in
                            viewModel.marketTypeFilter = viewModel.marketTypeFilters[index]
                        },
                        isPresented: isPresented
                    )
                }
            }
            .disabled(disabled)

            ThemeButton(text: "coin_markets.filter.verified".localized, style: viewModel.verifiedFilterActivated ? .primary : .secondary, size: .small) {
                viewModel.switchFilterType()
            }
            .disabled(disabled)
        }
    }

    @ViewBuilder private func list(viewItems: [CoinMarketsViewModel.ViewItem]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(viewItems, bottomSpacing: .margin16) { viewItem in
                cell(
                    imageUrl: viewItem.marketImageUrl.flatMap { URL(string: $0) },
                    market: viewItem.market,
                    pair: viewItem.pair,
                    volume: viewItem.volume,
                    fiatVolume: viewItem.fiatVolume,
                    verified: viewItem.verified,
                    action: viewItem.tradeUrl.map { tradeUrl in
                        {
                            UrlManager.open(url: tradeUrl)
                            stat(page: .coinMarkets, event: .open(page: .externalMarketPair))
                        }
                    }
                )
            }
            .onChange(of: viewModel.verifiedFilter) { _ in
                withAnimation {
                    proxy.scrollTo(viewItems.first!)
                }
            }
            .onChange(of: viewModel.marketTypeFilter) { _ in
                withAnimation {
                    proxy.scrollTo(viewItems.first!)
                }
            }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { index in
            cell(
                imageUrl: nil,
                market: "Stub Market",
                pair: "BTC / ETH",
                volume: "1.23M BTC",
                fiatVolume: "$123.45M",
                verified: index % 2 == 0
            )
            .redacted()
        }
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(imageUrl: URL?, market: String, pair: String, volume: String?, fiatVolume: String?, verified: Bool, action: (() -> Void)? = nil) -> some View {
        Cell(
            left: {
                KFImage.url(imageUrl)
                    .resizable()
                    .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                    .frame(width: .iconSize32, height: .iconSize32)
            },
            middle: {
                MultiText(
                    title: market,
                    badge: verified ? "coin_markets.verified".localized : nil,
                    subtitle: pair
                )
            },
            right: {
                RightMultiText(
                    title: volume,
                    subtitle: fiatVolume
                )
            },
            action: action
        )
    }
}
