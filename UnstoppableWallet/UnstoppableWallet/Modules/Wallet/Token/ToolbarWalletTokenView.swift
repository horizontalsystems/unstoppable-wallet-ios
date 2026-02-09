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
                    if WalletTokenToolbarItems.hasToolbarStatus(viewModel: viewModel) {
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

    // must be changed with items logic
    static func hasToolbarStatus(viewModel: WalletTokenViewModel) -> Bool {
        switch viewModel.state {
        case .notSynced: return viewModel.isReachable
        case .syncing, .customSyncing: return true
        default: return viewModel.wallet.account.watchAccount
        }
    }

    var body: some View {
        switch viewModel.state {
        case .notSynced:
            if viewModel.isReachable {
                Button(action: {
                    Coordinator.shared.presentBalanceError(wallet: viewModel.wallet, state: viewModel.state)
                }) {
                    Image("warning_filled").icon(colorStyle: .red)
                }
            }
        case let .syncing(progress, _, _), let .customSyncing(_, _, progress):
            ProgressView(value: max(0.1, Float(progress ?? 10) / 100))
                .progressViewStyle(DeterminiteSpinnerStyle())
                .frame(width: 20, height: 20)
                .spinning()
        default: EmptyView()
        }

        if viewModel.wallet.account.watchAccount {
            Button(action: {
                Coordinator.shared.presentCoinPage(coin: viewModel.wallet.coin, page: .tokenPage)
            }) {
                Image("chart")
            }
        }
    }
}
