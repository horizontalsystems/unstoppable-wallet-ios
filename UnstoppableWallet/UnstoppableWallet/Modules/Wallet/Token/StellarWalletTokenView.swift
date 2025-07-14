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
        WalletTokenView(wallet: wallet) {
            if let lockInfo = viewModel.lockInfo {
                ListSection {
                    ClickableRow(action: {
                        var description = "\("balance.token.locked.stellar.description".localized)\n\n\("balance.token.locked.stellar.description.currently_locked".localized)\n • 1 XLM - \("balance.token.locked.stellar.description.wallet_activation".localized)"

                        for asset in lockInfo.assets {
                            description += "\n • 0.5 XLM - \(asset)"
                        }

                        Coordinator.shared.present(info: .init(title: "balance.token.locked.stellar.title".localized, description: description))
                    }) {
                        HStack(spacing: .margin4) {
                            Text("balance.token.locked".localized).textCaptionSB()
                            Image("circle_information_20").themeIcon()
                        }

                        Spacer()

                        Text(viewModel.balanceHidden ? BalanceHiddenManager.placeholder : formatted(amount: lockInfo.amount)).textSubhead2(color: .themeLeah)
                    }
                }
                .themeListStyle(.bordered)
            }
        }
    }

    private func formatted(amount: Decimal) -> String {
        ValueFormatter.instance.formatFull(value: amount, decimalCount: wallet.decimals, symbol: wallet.coin.code) ?? "----"
    }
}
