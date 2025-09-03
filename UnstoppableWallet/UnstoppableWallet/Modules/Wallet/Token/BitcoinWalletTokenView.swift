import SwiftUI

struct BitcoinWalletTokenView: View {
    @StateObject var viewModel: BitcoinWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, adapter: BitcoinBaseAdapter) {
        _viewModel = StateObject(wrappedValue: BitcoinWalletTokenViewModel(adapter: adapter))
        self.wallet = wallet
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            ViewWithTransactionList(
                transactionListStatus: transactionsViewModel.transactionListStatus,
                content: {
                    Group {
                        WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
                        view(locked: viewModel.bitcoinBalanceData.locked, notRelayed: viewModel.bitcoinBalanceData.notRelayed)
                    }
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
    }

    @ViewBuilder private func view(locked: Decimal, notRelayed: Decimal) -> some View {
        if locked != 0 || notRelayed != 0 {
            VStack(spacing: 0) {
                view(
                    value: locked,
                    title: "balance.token.locked".localized,
                    info: .init(
                        title: "balance.token.locked.info.title".localized,
                        description: "balance.token.locked.info.description".localized
                    ),
                )

                view(
                    value: notRelayed,
                    title: "balance.token.not_relayed".localized,
                    info: .init(
                        title: "balance.token.not_relayed.info.title".localized,
                        description: "balance.token.not_relayed.info.description".localized
                    ),
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder private func view(value: Decimal, title: String, info: InfoDescription) -> some View {
        if value != 0 {
            WalletInfoView.infoView(
                title: title,
                info: info,
                value: infoAmount(value: value)
            )

            HorizontalDivider()
        }
    }

    private func infoAmount(value: Decimal) -> WalletInfoView.ValueFormatStyle {
        viewModel.balanceHidden
            ? .hiddenAmount
            : .fullAmount(.init(kind: .token(token: wallet.token), value: value))
    }
}
