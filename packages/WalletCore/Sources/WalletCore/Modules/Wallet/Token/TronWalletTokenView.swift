import SwiftUI

struct TronWalletTokenView: View {
    @StateObject var viewModel: TronWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, adapter: BaseTronAdapter) {
        _viewModel = StateObject(wrappedValue: TronWalletTokenViewModel(tronKit: adapter.tronKit, wallet: wallet))
        self.wallet = wallet
    }

    var body: some View {
        TronToolbarWalletTokenView(wallet: wallet, tronWalletViewModel: viewModel) { walletTokenViewModel, transactionsViewModel in
            let transactionListStatus = viewModel.accountActive ? transactionsViewModel.transactionListStatus : .inactiveWallet

            ViewWithTransactionList(
                transactionListStatus: transactionListStatus,
                content: {
                    WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
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
