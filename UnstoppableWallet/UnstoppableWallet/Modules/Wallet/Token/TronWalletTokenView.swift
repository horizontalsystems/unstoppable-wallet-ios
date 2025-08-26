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
            if viewModel.accountActive {
                ThemeList(bottomSpacing: .margin16) {
                    WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
                .themeListScrollHeader()
            } else {
                VStack(spacing: 0) {
                    WalletTokenTopView(viewModel: walletTokenViewModel)

                    PlaceholderViewNew(
                        icon: "warning_filled",
                        title: "balance.token.account.inactive.title".localized,
                        subtitle: "balance.token.account.inactive.description".localized
                    )
                }
            }
        }
    }
}
