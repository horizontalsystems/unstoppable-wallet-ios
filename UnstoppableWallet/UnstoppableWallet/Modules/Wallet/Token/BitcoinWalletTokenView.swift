import SwiftUI

struct BitcoinWalletTokenView: View {
    @StateObject var viewModel: BitcoinWalletTokenViewModel

    private let wallet: Wallet

    @State var info: InfoDescription?

    init(wallet: Wallet, adapter: BitcoinBaseAdapter) {
        _viewModel = StateObject(wrappedValue: BitcoinWalletTokenViewModel(adapter: adapter))
        self.wallet = wallet
    }

    var body: some View {
        WalletTokenView(wallet: wallet) {
            let locked = viewModel.bitcoinBalanceData.locked
            let notRelayed = viewModel.bitcoinBalanceData.notRelayed

            if locked != 0 || notRelayed != 0 {
                ListSection {
                    VStack(spacing: 0) {
                        if locked != 0 {
                            infoView(
                                title: "balance.token.locked".localized,
                                info: .init(title: "balance.token.locked.info.title".localized, description: "balance.token.locked.info.description".localized),
                                amount: locked
                            )
                        }

                        if notRelayed != 0 {
                            infoView(
                                title: "balance.token.not_relayed".localized,
                                info: .init(title: "balance.token.not_relayed.info.title".localized, description: "balance.token.not_relayed.info.description".localized),
                                amount: notRelayed
                            )
                        }
                    }
                }
                .themeListStyle(.bordered)
                .modifier(InfoBottomSheet(info: $info))
            }
        }
    }

    @ViewBuilder private func infoView(title: String, info: InfoDescription, amount: Decimal) -> some View {
        ClickableRow(action: {
            self.info = info
        }) {
            HStack(spacing: .margin4) {
                Text(title).textCaptionSB()
                Image("circle_information_20").themeIcon()
            }

            Spacer()

            Text(viewModel.balanceHidden ? BalanceHiddenManager.placeholder : formatted(amount: amount)).textSubhead2(color: .themeLeah)
        }
    }

    private func formatted(amount: Decimal) -> String {
        ValueFormatter.instance.formatFull(value: amount, decimalCount: wallet.decimals, symbol: wallet.coin.code) ?? "----"
    }
}
