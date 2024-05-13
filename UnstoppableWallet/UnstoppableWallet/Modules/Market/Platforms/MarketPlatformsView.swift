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
                loadingList()
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
            MarketPlatformView(platform: platform).ignoresSafeArea()
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

                Button(action: {
                    timePeriodSelectorPresented = true
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
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
        ScrollViewReader { _ in
            ThemeList(items: platforms) { platform in
                ClickableRow(action: {
                    presentedPlatform = platform
                }) {
                    let blockchain = platform.blockchain

                    KFImage.url(URL(string: blockchain.type.imageUrl))
                        .resizable()
                        .placeholder { RoundedRectangle(cornerRadius: .cornerRadius4).fill(Color.themeSteel20) }
                        .frame(width: .iconSize32, height: .iconSize32)

                    VStack(spacing: 1) {
                        HStack(spacing: .margin8) {
                            Text(blockchain.name).textBody()
                            Spacer()
                            Text(platform.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized).textBody()
                        }

                        HStack(spacing: .margin8) {
                            HStack(spacing: .margin4) {
                                if let rank = platform.rank {
                                    BadgeViewNew(text: "\(rank)", change: platform.ranks[viewModel.timePeriod].map { $0 - rank })
                                }

                                if let protocolsCount = platform.protocolsCount {
                                    Text("market.top.protocols".localized(String(protocolsCount))).textSubhead2()
                                }
                            }
                            Spacer()
                            DiffText(platform.changes[viewModel.timePeriod])
                        }
                    }
                }
            }
            .themeListStyle(.transparent)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ThemeList(items: Array(0 ... 10)) { _ in
            ListRow {
                RoundedRectangle(cornerRadius: .cornerRadius4)
                    .fill(Color.themeSteel20)
                    .frame(width: .iconSize32, height: .iconSize32)
                    .shimmering()

                VStack(spacing: 1) {
                    HStack(spacing: .margin8) {
                        Text("Ethereum").textBody().redacted(value: nil)
                        Spacer()
                        Text("$123.4 B").textBody().redacted(value: nil)
                    }

                    HStack(spacing: .margin8) {
                        HStack(spacing: .margin4) {
                            Text("12").textBody().redacted(value: nil)
                            Text("Protocols: 123").textSubhead2().redacted(value: nil)
                        }
                        Spacer()
                        DiffText(12.34).redacted(value: nil)
                    }
                }
            }
        }
        .themeListStyle(.transparent)
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }
}
