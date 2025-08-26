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
            ThemeList(bottomSpacing: .margin16) {
                WalletTokenTopView(viewModel: walletTokenViewModel).themeListTopView()

                let locked = viewModel.bitcoinBalanceData.locked
                let notRelayed = viewModel.bitcoinBalanceData.notRelayed

                if locked != 0 || notRelayed != 0 {
                    VStack(spacing: 0) {
                        if locked != 0 {
                            infoView(
                                title: "balance.token.locked".localized,
                                info: .init(title: "balance.token.locked.info.title".localized, description: "balance.token.locked.info.description".localized),
                                amount: locked
                            )

                            HorizontalDivider()
                        }

                        if notRelayed != 0 {
                            infoView(
                                title: "balance.token.not_relayed".localized,
                                info: .init(title: "balance.token.not_relayed.info.title".localized, description: "balance.token.not_relayed.info.description".localized),
                                amount: notRelayed
                            )

                            HorizontalDivider()
                        }
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

    @ViewBuilder private func infoView(title: String, info: InfoDescription, amount: Decimal) -> some View {
        Cell(
            middle: {
                MiddleTextIcon(text: title, icon: "information")
            },
            right: {
                RightTextIcon(
                    text: ComponentText(
                        text: viewModel.balanceHidden ? BalanceHiddenManager.placeholder : formatted(amount: amount),
                        colorStyle: .primary
                    )
                )
            },
            action: {
                Coordinator.shared.present(info: info)
            }
        )
    }

    private func formatted(amount: Decimal) -> String {
        ValueFormatter.instance.formatFull(value: amount, decimalCount: wallet.decimals, symbol: wallet.coin.code) ?? "----"
    }
}
