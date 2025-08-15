import Kingfisher
import MarketKit
import SwiftUI

struct MarketPlatformsView: View {
    @ObservedObject var viewModel: MarketPlatformsViewModel

    var body: some View {
        ThemeView(style: .list) {
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

    @ViewBuilder private func list(platforms: [TopPlatform]) -> some View {
        ScrollViewReader { proxy in
            ThemeList(platforms) { platform in
                let blockchain = platform.blockchain

                cell(
                    imageUrl: URL(string: blockchain.type.imageUrl),
                    name: blockchain.name,
                    marketCap: platform.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: viewModel.currency, value: $0) } ?? "n/a".localized,
                    protocolsCount: platform.protocolsCount,
                    rank: platform.rank,
                    rankChange: platform.rank.flatMap { rank in platform.ranks[viewModel.timePeriod].map { $0 - rank } },
                    diff: platform.changes[viewModel.timePeriod],
                    action: {
                        Coordinator.shared.present { isPresented in
                            MarketPlatformViewNew(isPresented: isPresented, platform: platform)
                                .ignoresSafeArea()
                        }

                        stat(page: .markets, section: .platforms, event: .openPlatform(chainUid: platform.blockchain.uid))
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
        ThemeList(Array(0 ... 10)) { index in
            cell(
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
        .scrollDisabled(true)
    }

    @ViewBuilder private func cell(imageUrl: URL?, name: String, marketCap: String, protocolsCount: Int?, rank: Int?, rankChange: Int?, diff: Decimal?, action: (() -> Void)? = nil) -> some View {
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
                    title: name,
                    subtitleBadge: rank.map { ComponentBadge(text: "\($0)", change: rankChange) },
                    subtitle: protocolsCount.map { "market.top.protocols".localized(String($0)) }
                )
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
}
