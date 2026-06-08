import SwiftUI

struct TronToolbarWalletTokenView<Content: View>: View {
    let wallet: Wallet
    private let content: (WalletTokenViewModel, TransactionsViewModel) -> Content

    init(wallet: Wallet, @ViewBuilder content: @escaping (WalletTokenViewModel, TransactionsViewModel) -> Content) {
        self.wallet = wallet
        self.content = content
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { viewModel, transactionsViewModel in
            content(viewModel, transactionsViewModel)
                .toolbar {
                    if WalletTokenToolbarItems.hasToolbarItems(viewModel: viewModel) {
                        ToolbarItem(placement: .topBarTrailing) {
                            WalletTokenToolbarItems(viewModel: viewModel)
                        }
                    }
                }
        }
    }
}
