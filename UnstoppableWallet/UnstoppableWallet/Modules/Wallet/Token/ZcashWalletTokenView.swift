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
                        view(birthday: viewModel.birthdayHeight?.description)
                        view(processing: viewModel.zcashBalanceData.processing, transparent: viewModel.zcashBalanceData.transparent)
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

    @ViewBuilder private func view(birthday: String?) -> some View {
        if let birthday {
            Cell(
                middle: {
                    MiddleTextIcon(text: "birthday_height.title".localized)
                },
                right: {
                    RightButtonText(text: birthday, icon: "copy_filled") {
                        CopyHelper.copyAndNotify(value: birthday)
                    }
                },
            )
            .background(Color.themeTyler)
        }
    }

    @ViewBuilder private func view(processing: Decimal, transparent: Decimal) -> some View {
        if processing != 0 || transparent > ZcashAdapter.minimalThreshold {
            VStack(spacing: 0) {
                view(processing: processing)
                view(transparent: transparent)
            }
        }
    }

    @ViewBuilder private func view(processing: Decimal) -> some View {
        if processing != 0 {
            WalletInfoView.infoView(
                title: "balance.token.processing".localized,
                info: .init(
                    title: "balance.token.processing.info.title".localized,
                    description: "balance.token.processing.info.description".localized
                ),
                value: infoAmount(value: processing)
            )

            HorizontalDivider()
        }
    }

    @ViewBuilder private func view(transparent: Decimal) -> some View {
        if transparent > ZcashAdapter.minimalThreshold {
            WalletInfoView.infoView(
                title: "balance.token.transparent".localized,
                value: infoAmount(value: transparent),
                action: {
                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                        BottomSheetView(
                            icon: .info,
                            title: "balance.token.transparent.info.title".localized,
                            items: [
                                .text(text: "balance.token.transparent.info.description".localized),
                            ],
                            buttons: [
                                .init(style: .yellow, title: "balance.token.shield".localized) {
                                    isPresented.wrappedValue = false

                                    Coordinator.shared.present { _ in
                                        ThemeNavigationStack {
                                            ShieldSendView(amount: viewModel.zcashBalanceData.transparent, address: nil)
                                        }
                                    }
                                },
                                .init(style: .transparent, title: "button.close".localized) {
                                    isPresented.wrappedValue = false
                                },
                            ],
                            isPresented: isPresented
                        )
                    }
                }
            )

            HorizontalDivider()
        }
    }

    private func infoAmount(value: Decimal) -> WalletInfoView.ValueFormatStyle {
        viewModel.balanceHidden
            ? .hiddenAmount
            : .fullAmount(.init(kind: .token(token: viewModel.wallet.token), value: value))
    }
}
