import SwiftUI

struct ToolbarWalletTokenView<Content: View>: View {
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
                            HStack(spacing: 8) {
                                WalletTokenToolbarItems(viewModel: viewModel)
                            }
                        }
                    }
                }
        }
    }
}

struct WalletTokenToolbarItems: View {
    @ObservedObject var viewModel: WalletTokenViewModel

    static func hasToolbarItems(viewModel: WalletTokenViewModel) -> Bool {
        viewModel.wallet.account.watchAccount
    }

    var body: some View {
        if viewModel.wallet.account.watchAccount {
            Button(action: {
                Coordinator.shared.presentCoinPage(coin: viewModel.wallet.coin, page: .tokenPage)
            }) {
                Image("chart")
            }
        }
    }
}
