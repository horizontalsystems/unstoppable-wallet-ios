import SwiftUI

struct WalletTokenView: View {
    private let wallet: Wallet

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            ThemeList(bottomSpacing: .margin16) {
                WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
                TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
            }
            .themeListScrollHeader()
        }
    }
}
