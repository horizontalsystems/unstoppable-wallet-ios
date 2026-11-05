import SwiftUI

struct SwapHistoryListView: View {
    @ObservedObject var viewModel: SwapHistoryViewModel
    let emptyText: String

    var body: some View {
        if viewModel.sections.isEmpty {
            PlaceholderViewNew(icon: "outgoingraw", subtitle: emptyText)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(TestTags.activityEmpty)
        } else {
            ThemeList(bottomSpacing: .margin16) {
                ForEach(viewModel.sections) { section in
                    Section {
                        ListForEachIdentifiable(section.viewItems) { viewItem in
                            Button(action: {
                                let swap = viewModel.correctedSwap(viewItem.swap)

                                Coordinator.shared.present { isPresented in
                                    SwapInfoView(swap: swap)
                                        .closeNavigation(isPresented: isPresented)
                                }
                            }) {
                                switch viewItem.swap.operation {
                                case .swap, .splitSwap: ItemView(viewItem: viewItem)
                                case .privateSend, .crossPay: OperationItemView(viewItem: viewItem)
                                }
                            }
                            .buttonStyle(CellButtonStyle())
                            .accessibilityIdentifier(TestTags.activityItem(viewItem.swap.uid))
                            .onAppear {
                                viewModel.onDisplay(section: section, viewItem: viewItem)
                            }
                        }
                    } header: {
                        ThemeListSectionHeader(text: section.title)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

extension SwapHistoryListView {
    struct ItemView: View {
        let viewItem: SwapHistoryViewModel.ViewItem

        var body: some View {
            HStack(spacing: 16) {
                HStack(spacing: 16) {
                    CoinIconView(token: viewItem.swap.tokenIn)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            ThemeText(viewItem.amountIn ?? "---", style: .subheadSB)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            ThemeText(viewItem.swap.tokenIn.coin.code, style: .subheadSB)
                        }

                        ThemeText(viewItem.fiatIn ?? " ", style: .captionSB, colorStyle: .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)

                viewItem.swap.status.view

                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(spacing: 4) {
                            ThemeText(viewItem.amountOut ?? "---", style: .subheadSB)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            ThemeText(viewItem.swap.tokenOut.coin.code, style: .subheadSB)
                        }

                        ThemeText(viewItem.fiatOut ?? " ", style: .captionSB, colorStyle: .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    CoinIconView(token: viewItem.swap.tokenOut)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
    }

    struct OperationItemView: View {
        let viewItem: SwapHistoryViewModel.ViewItem

        var body: some View {
            HStack(spacing: 16) {
                CoinIconView(token: viewItem.swap.tokenIn)

                VStack(alignment: .leading, spacing: 0) {
                    ThemeText(viewItem.swap.operation.title, style: .subheadSB)
                    ThemeText(viewItem.swap.status.historyTitle, style: .captionSB, colorStyle: statusColorStyle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 4) {
                        ThemeText("-\(viewItem.amountIn ?? "---")", style: .subheadSB)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        ThemeText(viewItem.swap.tokenIn.coin.code, style: .subheadSB)
                    }

                    ThemeText(viewItem.fiatIn.map { "-\($0)" } ?? " ", style: .captionSB, colorStyle: .secondary)
                }
            }
            .padding(16)
        }

        private var statusColorStyle: ColorStyle {
            switch viewItem.swap.status {
            case .completed: .green
            case .failed, .actionRequired: .red
            default: .secondary
            }
        }
    }
}
