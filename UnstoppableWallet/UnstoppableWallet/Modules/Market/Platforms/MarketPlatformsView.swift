import Kingfisher
import MarketKit
import SwiftUI

struct MarketPlatformsView: View {
    @ObservedObject var viewModel: MarketPlatformsViewModel

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
    }

    @ViewBuilder private func header(disabled: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button(action: {
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
                }) {
                    Text(viewModel.sortBy.title)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)

                Button(action: {
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
                }) {
                    Text(viewModel.timePeriod.shortTitle)
                }
                .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))
                .disabled(disabled)
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin8)
        }
    }

    @ViewBuilder private func list(platforms: [TopPlatform]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(platforms) { platform in
                ClickableRow(action: {
                    Coordinator.shared.present { isPresented in
                        MarketPlatformViewNew(isPresented: isPresented, platform: platform)
                            .ignoresSafeArea()
                    }

                    stat(page: .markets, section: .platforms, event: .openPlatform(chainUid: platform.blockchain.uid))
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
            .onChange(of: viewModel.sortBy) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
            .onChange(of: viewModel.timePeriod) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
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
            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
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
