import Kingfisher
import MarketKit
import SwiftUI

struct MarketPlatformsView: View {
    @ObservedObject var viewModel: MarketPlatformsViewModel

    @State private var sortBySelectorPresented = false
    @State private var timePeriodSelectorPresented = false

    @State private var presentedPlatform: TopPlatform?

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                VStack(spacing: 0) {
                    header(disabled: true)
                    loadingList()
                }
            case let .loaded(platforms):
                VStack(spacing: 0) {
                    header()
                    list(platforms: platforms)
                }
            case .failed:
                SyncErrorView {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .sheet(item: $presentedPlatform) { platform in
            let isPresented = Binding<Bool>(
                get: { presentedPlatform != nil },
                set: { newValue in if !newValue { presentedPlatform = nil }}
            )

            MarketPlatformViewNew(isPresented: isPresented, platform: platform).ignoresSafeArea()
                .onFirstAppear { stat(page: .markets, section: .platforms, event: .openPlatform(chainUid: platform.blockchain.uid)) }
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

    @ViewBuilder private func list(platforms: [TopPlatform]) -> some View {
        ThemeList(platforms) { platform in
            ClickableRow(action: {
                presentedPlatform = platform
            }) {
                let blockchain = platform.blockchain

                itemContent(
                    imageUrl: URL(string: blockchain.type.imageUrl),
                    name: blockchain.name,
                    marketCap: platform.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    protocolsCount: platform.protocolsCount,
                    rank: platform.rank,
                    rankChange: platform.rank.flatMap { rank in platform.ranks[viewModel.timePeriod].map { $0 - rank } },
                    diff: platform.changes[viewModel.timePeriod]
                )
            }
        }
        .themeListStyle(.transparent)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(Array(0 ... 10)) { index in
            ListRow {
                itemContent(
                    imageUrl: nil,
                    name: "Blockchain",
                    marketCap: "$123.4 B",
                    protocolsCount: 123,
                    rank: 12,
                    rankChange: nil,
                    diff: index % 2 == 0 ? 12.34 : -12.34
                )
                .redacted()
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(imageUrl: URL?, name: String, marketCap: String, protocolsCount: Int?, rank: Int?, rankChange: Int?, diff: Decimal?) -> some View {
        KFImage.url(imageUrl)
            .resizable()
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeSteel20) }
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
            .frame(width: .iconSize32, height: .iconSize32)

        VStack(spacing: 1) {
            HStack(spacing: .margin8) {
                Text(name).textBody()
                Spacer()
                Text(marketCap).textBody()
            }

            HStack(spacing: .margin8) {
                HStack(spacing: .margin4) {
                    if let rank {
                        BadgeViewNew(text: "\(rank)", change: rankChange)
                    }

                    if let protocolsCount {
                        Text("market.top.protocols".localized(String(protocolsCount))).textSubhead2()
                    }
                }
                Spacer()
                DiffText(diff)
            }
        }
    }
}
