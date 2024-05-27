import Kingfisher
import MarketKit
import SwiftUI

struct MarketPairsView: View {
    @ObservedObject var viewModel: MarketPairsViewModel

    var body: some View {
        ThemeView {
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
                    viewModel.volumeSortOrder.toggle()
                }) {
                    Text("market.pairs.volume".localized)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .custom(image: volumeSortIcon())))
                .disabled(disabled)
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
    }

    @ViewBuilder private func list(pairs: [MarketPair]) -> some View {
        ThemeList(pairs) { pair in
            ClickableRow(action: {
                if let tradeUrl = pair.tradeUrl {
                    UrlManager.open(url: tradeUrl)
                }
            }) {
                itemContent(
                    frontImageUrl: pair.baseCoinUid.flatMap { URL(string: Coin.imageUrl(uid: $0)) },
                    backImageUrl: pair.targetCoinUid.flatMap { URL(string: Coin.imageUrl(uid: $0)) },
                    base: pair.base,
                    target: pair.target,
                    volume: pair.volume.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    marketName: pair.marketName,
                    rank: pair.rank,
                    price: pair.price.flatMap { ValueFormatter.instance.formatShort(value: $0, decimalCount: 8, symbol: pair.target) } ?? "n/a".localized
                )
            }
        }
        .themeListStyle(.transparent)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { _ in
            ListRow {
                itemContent(
                    frontImageUrl: nil,
                    backImageUrl: nil,
                    base: "CODE",
                    target: "CODE",
                    volume: "$123.4 B",
                    marketName: "Market Name",
                    rank: 12,
                    price: "123 CODE"
                )
                .redacted()
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(frontImageUrl: URL?, backImageUrl: URL?, base: String, target: String, volume: String, marketName: String, rank: Int, price: String) -> some View {
        ZStack(alignment: .leading) {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.themeTyler)
                        .frame(width: .iconSize32, height: .iconSize32)

                    KFImage.url(backImageUrl)
                        .resizable()
                        .placeholder { Circle().fill(Color.themeSteel20) }
                        .clipShape(Circle())
                        .frame(width: .iconSize32, height: .iconSize32)
                }
            }

            ZStack {
                Circle()
                    .fill(Color.themeTyler)
                    .frame(width: .iconSize32, height: .iconSize32)

                KFImage.url(frontImageUrl)
                    .resizable()
                    .placeholder { Circle().fill(Color.themeSteel20) }
                    .clipShape(Circle())
                    .frame(width: .iconSize32, height: .iconSize32)
            }
        }
        .frame(width: 52)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text("\(base) / \(target)").textBody()
                Spacer()
                Text(volume).textBody()
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    BadgeViewNew(text: "\(rank)")
                    Text(marketName).textSubhead2()
                }
                Spacer()
                Text(price).textSubhead2()
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
