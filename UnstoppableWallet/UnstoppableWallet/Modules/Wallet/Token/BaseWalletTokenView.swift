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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    switch viewModel.state {
                    case .notSynced:
                        if viewModel.isReachable {
                            Button(action: {
                                Coordinator.shared.presentBalanceError(wallet: viewModel.wallet, state: viewModel.state)
                            }) {
                                Image("warning_filled").icon(colorStyle: .red)
                            }
                        }
                    case let .syncing(progress, _), let .customSyncing(_, _, progress):
                        ProgressView(value: max(0.1, Float(progress ?? 10) / 100))
                            .progressViewStyle(DeterminiteSpinnerStyle())
                            .frame(width: 20, height: 20)
                            .spinning()
                    default:
                        EmptyView()
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
        }
    }
}
