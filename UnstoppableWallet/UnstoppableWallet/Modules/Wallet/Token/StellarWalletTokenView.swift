import StellarKit
import SwiftUI

struct StellarWalletTokenView: View {
    @StateObject var viewModel: StellarWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, stellarKit: StellarKit.Kit, asset: Asset) {
        _viewModel = StateObject(wrappedValue: StellarWalletTokenViewModel(stellarKit: stellarKit, asset: asset))
        self.wallet = wallet
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            ViewWithTransactionList(
                transactionListStatus: transactionsViewModel.transactionListStatus,
                content: {
                    Group {
                        WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
                        view(lockInfo: viewModel.lockInfo)
                    }
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
    }

    @ViewBuilder private func view(lockInfo: StellarWalletTokenViewModel.LockInfo?) -> some View {
        if let lockInfo {
            VStack(spacing: 0) {
                WalletInfoView.infoView(
                    title: "balance.token.locked".localized,
                    value: lockedValue(lockInfo: lockInfo)
                ) {
                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                        BottomSheetView(items: [
                            .title(title: "balance.token.locked".localized),
                            .list(items: lockedItems(lockInfo: lockInfo)),
                            .footer(text: "balance.token.locked.stellar.description".localized),
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

    private func lockedItems(lockInfo: StellarWalletTokenViewModel.LockInfo) -> [BSModule.ListItem] {
        var items: [BSModule.ListItem] = [
            .init(
                title: "balance.token.locked.stellar.description.wallet_activation".localized,
                value: ComponentText(text: "1 XLM", colorStyle: .primary)
            ),
        ]

        for asset in lockInfo.assets {
            items.append(
                .init(
                    title: asset,
                    value: ComponentText(text: "0.5 XLM", colorStyle: .primary)
                )
            )
        }

        return items
    }

    private func lockedValue(lockInfo: StellarWalletTokenViewModel.LockInfo) -> WalletInfoView.ValueFormatStyle {
        viewModel.balanceHidden
            ? .hiddenAmount
            : .fullAmount(.init(kind: .token(token: wallet.token), value: lockInfo.amount))
    }
}
