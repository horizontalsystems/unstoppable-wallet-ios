import SwiftUI

struct TronWalletTokenView: View {
    @StateObject var viewModel: TronWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, adapter: BaseTronAdapter) {
        _viewModel = StateObject(wrappedValue: TronWalletTokenViewModel(tronKit: adapter.tronKit))
        self.wallet = wallet
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
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
    }
}

extension TransactionListStatus {
    static let inactiveWallet = TransactionListStatus(
        id: "inactive_wallet",
        icon: "warning_filled",
        title: "balance.token.account.inactive.title".localized,
        subtitle: "balance.token.account.inactive.description".localized
    )
}
