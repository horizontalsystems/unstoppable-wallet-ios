import SwiftUI

struct MoneroWalletTokenView: View {
    @StateObject var viewModel: MoneroWalletTokenViewModel

    init(wallet: Wallet, adapter: MoneroAdapter) {
        _viewModel = StateObject(wrappedValue: MoneroWalletTokenViewModel(adapter: adapter, wallet: wallet))
    }

    var body: some View {
        BaseWalletTokenView(wallet: viewModel.wallet) { walletTokenViewModel, transactionsViewModel in
            ViewWithTransactionList(
                transactionListStatus: transactionsViewModel.transactionListStatus,
                content: {
                    VStack(spacing: 0) {
                        WalletTokenTopView(viewModel: walletTokenViewModel) {
                            if case .moneroWatchAccount = viewModel.wallet.account.type {
                                AlertCardView(.init(text: "watch_address.monero_warning.description".localized))
                                    .padding(16)
                            }
                        }

                        if let birthdayHeight = viewModel.birthdayHeight {
                            view(birthdayHeight: birthdayHeight)
                            HorizontalDivider()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
    }

    @ViewBuilder private func view(birthdayHeight: Int) -> some View {
        Cell(
            middle: {
                MiddleTextIcon(text: "birthday_height.title".localized)
            },
            right: {
                RightTextIcon(text: String(birthdayHeight), icon: "arrow_b_right")
            },
            action: {
                let blockchain = viewModel.wallet.token.blockchain

                guard let provider = BirthdayInputProviderFactory.provider(blockchainType: blockchain.type) else {
                    return
                }

                Coordinator.shared.present { _ in
                    BirthdayInputView(blockchain: blockchain, initialHeight: birthdayHeight, provider: provider) { birthdayHeight in
                        viewModel.onChange(birthdayHeight: birthdayHeight)
                    }
                }
            }
        )
    }
}
