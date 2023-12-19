import Kingfisher
import MarketKit
import SwiftUI

struct CoinMarketsView: View {
    @StateObject private var viewModel: CoinMarketsViewModel

    @State private var hasAppeared = false

    init(coin: Coin) {
        _viewModel = StateObject(wrappedValue: CoinMarketsViewModel(coin: coin))
    }

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
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            viewModel.onFirstAppear()
        }
    }

    @ViewBuilder private func list(viewItems: [CoinMarketsViewModel.ViewItem]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    viewModel.switchFilterType()
                }) {
                    Text(viewModel.filterTypeInfo.text)
                }
                .buttonStyle(SelectorButtonStyle(count: viewModel.filterTypeInfo.count, selectedIndex: viewModel.filterTypeInfo.selectedIndex))

                Spacer()

                Button(action: {
                    viewModel.switchVolumeType()
                }) {
                    Text(viewModel.volumeTypeInfo.text)
                }
                .buttonStyle(SelectorButtonStyle(count: viewModel.volumeTypeInfo.count, selectedIndex: viewModel.volumeTypeInfo.selectedIndex))
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)

            ScrollViewReader { proxy in
                ThemeList(items: viewItems) { viewItem in
                    if let tradeUrl = viewItem.tradeUrl {
                        ClickableRow(action: {
                            UrlManager.open(url: tradeUrl)
                        }) {
                            listItemContent(viewItem: viewItem)
                        }
                    } else {
                        ListRow {
                            listItemContent(viewItem: viewItem)
                        }
                    }
                }
                .themeListStyle(.transparent)
                .onChange(of: viewModel.filterTypeInfo) { _ in
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
                RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeSteel20)
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

                if let rate = viewItem.rate {
                    Text(rate)
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

                if let volume = viewItem.volume {
                    HStack(spacing: .margin4) {
                        Text("market.market_field.vol".localized)
                            .font(.themeSubhead2)
                            .foregroundColor(.themeJacob)

                        Text(volume)
                            .font(.themeSubhead2)
                            .foregroundColor(.themeGray)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
