import SwiftUI

struct SwapHistoryView: View {
    @StateObject var viewModel = SwapHistoryViewModel()
    @Binding var isPresented: Bool

    @State private var path = NavigationPath()

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
                VStack(spacing: 0) {
                    if viewModel.sections.isEmpty {
                        PlaceholderViewNew(icon: "outgoingraw", subtitle: "swap_history.empty".localized)
                    } else {
                        ThemeList(bottomSpacing: 16) {
                            ForEach(viewModel.sections) { section in
                                Section {
                                    ListForEachIdentifiable(section.viewItems) { viewItem in
                                        Button(action: {
                                            path.append(viewItem.swap)
                                        }) {
                                            ItemView(viewItem: viewItem)
                                        }
                                        .buttonStyle(CellButtonStyle())
                                        .onAppear {
                                            viewModel.onDisplay(section: section, viewItem: viewItem)
                                        }
                                    }
                                } header: {
                                    ThemeText(section.title, style: .subheadSB, colorStyle: .andy)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 24)
                                        .padding(.bottom, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.themeLawrence)
                                        .listRowInsets(EdgeInsets())
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("swap_history.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.close".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh".localized) {
                        viewModel.refresh()
                    }
                }
            }
            .navigationDestination(for: Swap.self) { swap in
                SwapInfoView(swap: swap)
            }
        }
    }
}

extension SwapHistoryView {
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

                switch viewItem.swap.status {
                case .completed: ThemeImage("done_e_filled", size: 20, colorStyle: .green)
                case .failed: ThemeImage("warning_filled", size: 20, colorStyle: .red)
                case .refunded: ThemeImage("arrow_return", size: 20, colorStyle: .secondary)
                default: ThemeImage("arrow_m_right", size: 20, colorStyle: .secondary)
                }

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
}
