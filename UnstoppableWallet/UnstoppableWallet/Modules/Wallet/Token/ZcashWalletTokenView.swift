import SwiftUI

struct ZcashWalletTokenView: View {
    @StateObject var viewModel: ZcashWalletTokenViewModel

    private let wallet: Wallet

    @State var info: InfoDescription?
    @State var transparentPresented = false
    @State var shieldPresented = false

    init(wallet: Wallet, adapter: ZcashAdapter) {
        _viewModel = StateObject(wrappedValue: ZcashWalletTokenViewModel(adapter: adapter))
        self.wallet = wallet
    }

    var body: some View {
        WalletTokenView(wallet: wallet) {
            let processing = viewModel.zcashBalanceData.processing
            let transparent = viewModel.zcashBalanceData.transparent

            if processing != 0 || transparent > ZcashAdapter.minimalThreshold {
                ListSection {
                    VStack(spacing: 0) {
                        if processing != 0 {
                            infoView(
                                title: "balance.token.processing".localized,
                                amount: processing
                            ) {
                                info = .init(title: "balance.token.processing.info.title".localized, description: "balance.token.processing.info.description".localized)
                            }
                        }

                        if transparent > ZcashAdapter.minimalThreshold {
                            infoView(
                                title: "balance.token.transparent".localized,
                                amount: transparent
                            ) {
                                transparentPresented = true
                            }
                        }
                    }
                }
                .themeListStyle(.bordered)
            }
        }
        .modifier(InfoBottomSheet(info: $info))
        .bottomSheet(isPresented: $transparentPresented) {
            BottomSheetView(
                icon: .info,
                title: "balance.token.transparent.info.title".localized,
                items: [
                    .text(text: "balance.token.transparent.info.description".localized),
                ],
                buttons: [
                    .init(style: .yellow, title: "balance.token.shield".localized) {
                        transparentPresented = false
                        shieldPresented = true
                    },
                    .init(style: .transparent, title: "button.close".localized) {
                        transparentPresented = false
                    },
                ],
                isPresented: $transparentPresented
            )
        }
        .sheet(isPresented: $shieldPresented) {
            ThemeNavigationView {
                ShieldSendView(amount: viewModel.zcashBalanceData.transparent, address: nil)
            }
        }
    }

    @ViewBuilder private func infoView(title: String, amount: Decimal, action: @escaping () -> Void) -> some View {
        ClickableRow(action: action) {
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
