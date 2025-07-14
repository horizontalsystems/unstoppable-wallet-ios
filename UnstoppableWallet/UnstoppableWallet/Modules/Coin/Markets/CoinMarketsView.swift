import Kingfisher
import MarketKit
import SwiftUI

struct CoinMarketsView: View {
    @ObservedObject var viewModel: CoinMarketsViewModel

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(viewItems):
                if viewItems.isEmpty {
                    PlaceholderViewNew(image: Image("no_data_48"), text: "coin_markets.empty".localized)
                } else {
                    list(viewItems: viewItems)
                }
            case .failed:
                SyncErrorView {
                    viewModel.onRetry()
                }
            }
        }
    }

    @ViewBuilder private func list(viewItems: [CoinMarketsViewModel.ViewItem]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
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
                }) {
                    Text(viewModel.marketTypeFilter.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))

                Spacer()

                if viewModel.verifiedFilterActivated {
                    Button(action: {
                        viewModel.switchFilterType()
                    }) {
                        Text(viewModel.verifiedFilter.title)
                    }
                    .buttonStyle(SecondaryActiveButtonStyle())
                } else {
                    Button(action: {
                        viewModel.switchFilterType()
                    }) {
                        Text(viewModel.verifiedFilter.title)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)

            ScrollViewReader { proxy in
                ThemeList(viewItems, bottomSpacing: .margin16) { viewItem in
                    if let tradeUrl = viewItem.tradeUrl {
                        ClickableRow(action: {
                            UrlManager.open(url: tradeUrl)
                            stat(page: .coinMarkets, event: .open(page: .externalMarketPair))
                        }) {
                            listItemContent(viewItem: viewItem)
                        }
                    } else {
                        ListRow {
                            listItemContent(viewItem: viewItem)
                        }
                    }
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
    }

    @ViewBuilder private func listItemContent(viewItem: CoinMarketsViewModel.ViewItem) -> some View {
        KFImage.url(viewItem.marketImageUrl.flatMap { URL(string: $0) })
            .resizable()
            .placeholder {
                RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeBlade)
            }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(viewItem.market)
                    .font(.themeBody)
                    .foregroundColor(.themeLeah)
                    .lineLimit(1)

                if viewItem.verified {
                    BadgeViewNew(text: "coin_markets.verified".localized)
                }

                Spacer()

                if let volume = viewItem.volume {
                    Text(volume)
                        .font(.themeBody)
                        .foregroundColor(.themeLeah)
                        .lineLimit(1)
                }
            }

            HStack(spacing: .margin8) {
                Text(viewItem.pair)
                    .font(.themeSubhead2)
                    .foregroundColor(.themeGray)
                    .lineLimit(1)

                Spacer()

                if let fiatVolume = viewItem.fiatVolume {
                    Text(fiatVolume)
                        .font(.themeSubhead2)
                        .foregroundColor(.themeGray)
                        .lineLimit(1)
                }
            }
        }
    }
}
