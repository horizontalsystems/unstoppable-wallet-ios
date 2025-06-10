import SwiftUI

struct TronWalletTokenView: View {
    @StateObject var viewModel: TronWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, adapter: BaseTronAdapter) {
        _viewModel = StateObject(wrappedValue: TronWalletTokenViewModel(tronKit: adapter.tronKit))
        self.wallet = wallet
    }

    var body: some View {
        WalletTokenView(wallet: wallet) {
            if !viewModel.accountActive {
                HighlightedTextView(
                    title: "balance.token.account.inactive.title".localized,
                    text: "balance.token.account.inactive.description".localized
                )
            }
        }
    }
}
