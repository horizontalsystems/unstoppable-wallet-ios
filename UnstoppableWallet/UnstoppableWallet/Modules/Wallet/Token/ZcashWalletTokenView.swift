import SwiftUI

struct ZcashWalletTokenView: View {
    @StateObject var viewModel: ZcashWalletTokenViewModel

    init(wallet: Wallet, adapter: ZcashAdapter) {
        _viewModel = StateObject(wrappedValue: ZcashWalletTokenViewModel(adapter: adapter, wallet: wallet))
    }

    var body: some View {
        BaseWalletTokenView(wallet: viewModel.wallet) { walletTokenViewModel, transactionsViewModel in
            ViewWithTransactionList(
                transactionListStatus: transactionsViewModel.transactionListStatus,
                content: {
                    VStack(spacing: 0) {
                        WalletTokenTopView(viewModel: walletTokenViewModel)
                        if viewModel.zCashBalanceData.transparent > ZcashAdapter.minimalThreshold {
                            view(transparent: viewModel.zCashBalanceData.transparent)
                            HorizontalDivider()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
    }

    @ViewBuilder private func view(transparent: Decimal) -> some View {
        Cell(
            middle: {
                MiddleTextIcon(text: "balance.token.transparent".localized)
            },
            right: {
                RightTextIcon(
                    text: ComponentText(
                        text: infoAmount(value: transparent).formatted,
                        colorStyle: .yellow
                    ),
                    icon: ComponentImage("warning_filled", colorStyle: .yellow)
                )
            },
            action: {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    BottomSheetView(
                        items: [
                            .title(
                                icon: ThemeImage.shieldOff,
                                title: "balance.token.transparent.info.title".localized
                            ),
                            .text(text: "balance.token.transparent.info.description".localized),
                            .buttonGroup(.init(buttons: [
                                    .init(style: .gray, title: "button.cancel".localized) {
                                        isPresented.wrappedValue = false
                                    },
                                    .init(style: .yellow, title: "balance.token.shield".localized) {
                                        isPresented.wrappedValue = false

                                        Coordinator.shared.present { _ in
                                            ThemeNavigationStack {
                                                ShieldSendView(amount: viewModel.zCashBalanceData.transparent, address: nil)
                                            }
                                        }
                                    },
                                ],
                                alignment: .horizontal)),
                        ],
                    )
                }
            }
        )
    }

    private func infoAmount(value: Decimal) -> WalletInfoView.ValueFormatStyle {
        viewModel.balanceHidden
            ? .hiddenAmount
            : .fullAmount(.init(kind: .token(token: viewModel.wallet.token), value: value))
    }
}
