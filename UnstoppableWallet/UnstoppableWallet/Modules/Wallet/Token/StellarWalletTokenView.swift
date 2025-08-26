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
            ThemeList(bottomSpacing: .margin16) {
                WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()

                if let lockInfo = viewModel.lockInfo {
                    VStack(spacing: 0) {
                        Cell(
                            middle: {
                                MiddleTextIcon(text: "balance.token.locked".localized, icon: "information")
                            },
                            right: {
                                RightTextIcon(
                                    text: ComponentText(
                                        text: viewModel.balanceHidden ? BalanceHiddenManager.placeholder : formatted(amount: lockInfo.amount),
                                        colorStyle: .primary
                                    )
                                )
                            },
                            action: {
                                var description = "\("balance.token.locked.stellar.description".localized)\n\n\("balance.token.locked.stellar.description.currently_locked".localized)\n • 1 XLM - \("balance.token.locked.stellar.description.wallet_activation".localized)"

                                for asset in lockInfo.assets {
                                    description += "\n • 0.5 XLM - \(asset)"
                                }

                                Coordinator.shared.present(info: .init(title: "balance.token.locked.stellar.title".localized, description: description))
                            }
                        )

                        HorizontalDivider()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

                TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
            }
            .themeListScrollHeader()
        }
    }

    private func formatted(amount: Decimal) -> String {
        ValueFormatter.instance.formatFull(value: amount, decimalCount: wallet.decimals, symbol: wallet.coin.code) ?? "----"
    }
}
