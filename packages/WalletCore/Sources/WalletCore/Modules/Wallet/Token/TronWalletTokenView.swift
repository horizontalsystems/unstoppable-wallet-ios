import SwiftUI

struct TronWalletTokenView: View {
    @StateObject var viewModel: TronWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, adapter: BaseTronAdapter) {
        _viewModel = StateObject(wrappedValue: TronWalletTokenViewModel(adapter: adapter, wallet: wallet))
        self.wallet = wallet
    }

    var body: some View {
        TronToolbarWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            let transactionListStatus = viewModel.accountActive ? transactionsViewModel.transactionListStatus : .inactiveWallet

            ViewWithTransactionList(
                transactionListStatus: transactionListStatus,
                content: {
                    WalletTokenTopView(
                        viewModel: walletTokenViewModel,
                        status: {
                            TronWalletTokenHeaderStatusView(viewModel: walletTokenViewModel, tronViewModel: viewModel)
                        },
                        content: {
                            EmptyView()
                        }
                    )
                    .themeListTopView()
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
        .onFirstAppear {
            viewModel.onFirstAppear()
        }
    }
}

extension TransactionListStatus {
    static let inactiveWallet = TransactionListStatus(
        id: "inactive_wallet",
        icon: "outgoingraw",
        subtitle: "balance.token.account.inactive.description".localized
    )
}
