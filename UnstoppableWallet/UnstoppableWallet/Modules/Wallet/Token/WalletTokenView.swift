import SwiftUI

struct WalletTokenView: View {
    private let wallet: Wallet

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            ViewWithTransactionList(
                transactionListStatus: transactionsViewModel.transactionListStatus,
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
