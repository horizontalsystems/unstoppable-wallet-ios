import StellarKit
import SwiftUI

struct StellarWalletTokenView: View {
    @StateObject var viewModel: StellarWalletTokenViewModel

    private let wallet: Wallet

    init(wallet: Wallet, stellarKit: StellarKit.Kit, asset: Asset) {
        _viewModel = StateObject(wrappedValue: StellarWalletTokenViewModel(stellarKit: stellarKit, asset: asset))
        self.wallet = wallet
    }

    var body: some View {
        BaseWalletTokenView(wallet: wallet) { walletTokenViewModel, transactionsViewModel in
            ViewWithTransactionList(
                transactionListStatus: transactionsViewModel.transactionListStatus,
                content: {
                    Group {
                        WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()
                        view(lockInfo: viewModel.lockInfo)
                    }
                },
                transactionList: {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
                }
            )
        }
    }

    @ViewBuilder private func view(lockInfo _: StellarWalletTokenViewModel.LockInfo?) -> some View {
        if let lockInfo = viewModel.lockInfo {
            VStack(spacing: 0) {
                WalletInfoView.infoView(
                    title: "balance.token.locked".localized,
                    info: lockedDescription(lockInfo: lockInfo),
                    value: lockedValue(lockInfo: lockInfo)
                )

                HorizontalDivider()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    private func lockedDescription(lockInfo: StellarWalletTokenViewModel.LockInfo) -> InfoDescription {
        var description = "\("balance.token.locked.stellar.description".localized)\n\n\("balance.token.locked.stellar.description.currently_locked".localized)\n • 1 XLM - \("balance.token.locked.stellar.description.wallet_activation".localized)"

        for asset in lockInfo.assets {
            description += "\n • 0.5 XLM - \(asset)"
        }

        return .init(title: "balance.token.locked.stellar.title".localized, description: description)
    }

    private func lockedValue(lockInfo: StellarWalletTokenViewModel.LockInfo) -> WalletInfoView.ValueFormatStyle {
        viewModel.balanceHidden
            ? .hiddenAmount
            : .fullAmount(.init(kind: .token(token: wallet.token), value: lockInfo.amount))
    }
}
