import SwiftUI

struct BaseWalletTokenView<Content: View>: View {
    @StateObject var viewModel: WalletTokenViewModel
    @StateObject var transactionsViewModel: TransactionsViewModel

    private let content: (WalletTokenViewModel, TransactionsViewModel) -> Content

    init(wallet: Wallet, @ViewBuilder content: @escaping (WalletTokenViewModel, TransactionsViewModel) -> Content) {
        _viewModel = StateObject(wrappedValue: WalletTokenViewModel(wallet: wallet))
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(transactionFilter: .init(token: wallet.token)))
        self.content = content
    }

    var body: some View {
        ThemeView(style: .list) {
            content(viewModel, transactionsViewModel)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            if viewModel.state.isNotSynced {
                Coordinator.shared.presentBalanceError(wallet: viewModel.wallet, state: viewModel.state, showNotReachable: false)
            }
        }
        .navigationTitle(viewModel.title)
        .toolbarRole(.editor)
    }
}
