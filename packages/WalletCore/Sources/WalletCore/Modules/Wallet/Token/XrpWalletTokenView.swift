import SwiftUI
import XrpKit

struct XrpWalletTokenView: View {
    @StateObject var viewModel: XrpWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, adapter: XrpAdapter) {
        _viewModel = StateObject(wrappedValue: XrpWalletTokenViewModel(adapter: adapter))
        self.wallet = wallet
    }

    var body: some View {
        ToolbarWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            let transactionListStatus = viewModel.accountActive ? transactionsViewModel.transactionListStatus : .xrpInactiveWallet

            ViewWithTransactionList(
                transactionListStatus: transactionListStatus,
                content: {
                    Group {
                        WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
                        view(reserveInfo: viewModel.reserveInfo)
                    }
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
    }

    @ViewBuilder private func view(reserveInfo: XrpReserveInfo?) -> some View {
        if let reserveInfo {
            VStack(spacing: 0) {
                WalletInfoView.infoView(
                    title: "balance.token.locked".localized,
                    value: lockedValue(total: reserveInfo.total)
                ) {
                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                        BottomSheetView(items: [
                            .title(title: "balance.token.locked".localized),
                            .list(items: lockedItems(reserveInfo: reserveInfo)),
                            .footer(text: "balance.token.locked.xrp.description".localized),
                            .buttonGroup(.init(buttons: [
                                .init(style: .gray, title: "button.close".localized) {
                                    isPresented.wrappedValue = false
                                },
                            ])),
                        ])
                    }
                }

                HorizontalDivider()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    // one row per reserve source, as Android `XrpAdapter.reserveInfo`: the base reserve, each trust
    // line, then every other owned object (offers, escrows, ...) folded into one row
    private func lockedItems(reserveInfo: XrpReserveInfo) -> [BSModule.ListItem] {
        var items: [BSModule.ListItem] = [
            .init(
                title: "balance.token.locked.stellar.description.wallet_activation".localized,
                value: ComponentText(text: xrpString(reserveInfo.baseReserve), colorStyle: .primary)
            ),
        ]

        for trustLine in reserveInfo.trustLines {
            items.append(
                .init(
                    title: XrpKit.Kit.displayCurrencyCode(trustLine.currency),
                    value: ComponentText(text: xrpString(reserveInfo.ownerReserve), colorStyle: .primary)
                )
            )
        }

        if reserveInfo.otherObjectCount > 0 {
            items.append(
                .init(
                    title: "balance.token.locked.xrp.other_objects".localized(String(reserveInfo.otherObjectCount)),
                    value: ComponentText(text: xrpString(reserveInfo.ownerReserve * Decimal(reserveInfo.otherObjectCount)), colorStyle: .primary)
                )
            )
        }

        return items
    }

    private func xrpString(_ value: Decimal) -> String {
        AppValue(token: wallet.token, value: value).formattedFull() ?? ""
    }

    private func lockedValue(total: Decimal) -> WalletInfoView.ValueFormatStyle {
        viewModel.balanceHidden
            ? .hiddenAmount
            : .fullAmount(.init(kind: .token(token: wallet.token), value: total))
    }
}

extension TransactionListStatus {
    static let xrpInactiveWallet = TransactionListStatus(
        id: "xrp_inactive_wallet",
        icon: "outgoingraw",
        subtitle: "balance.token.xrp.account_not_activated".localized
    )
}
