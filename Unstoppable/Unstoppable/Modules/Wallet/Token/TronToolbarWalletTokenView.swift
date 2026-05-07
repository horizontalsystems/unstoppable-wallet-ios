import SwiftUI

struct TronToolbarWalletTokenView<Content: View>: View {
    let wallet: Wallet
    @ObservedObject var tronWalletViewModel: TronWalletTokenViewModel
    private let content: (WalletTokenViewModel, TransactionsViewModel) -> Content

    init(wallet: Wallet, tronWalletViewModel: TronWalletTokenViewModel, @ViewBuilder content: @escaping (WalletTokenViewModel, TransactionsViewModel) -> Content) {
        self.wallet = wallet
        self.tronWalletViewModel = tronWalletViewModel
        self.content = content
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { viewModel, transactionsViewModel in
            content(viewModel, transactionsViewModel)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        // show default toolbars if it's present
                        if WalletTokenToolbarItems.hasToolbarStatus(viewModel: viewModel) {
                            WalletTokenToolbarItems(viewModel: viewModel)

                        } else if !tronWalletViewModel.accountActive {
                            Button(action: {
                                tronWalletViewModel.showPopup()
                            }) {
                                Image("warning_filled").icon(colorStyle: .yellow)
                            }
                        }
                    }
                }
        }
    }
}
