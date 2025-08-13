import MarketKit
import MessageUI
import SwiftUI

struct BalanceErrorBottomView: View {
    @StateObject var viewModel: BalanceErrorBottomViewModel
    @Binding var isPresented: Bool

    init(wallet: Wallet, error: String, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: BalanceErrorBottomViewModel(wallet: wallet, error: error))
        _isPresented = isPresented
    }

    var body: some View {
        BottomSheetView(
            icon: .local(name: "warning_2_24", tint: .themeLucian),
            title: "balance_error.sync_error".localized,
            buttons: buttons(item: viewModel.item),
            isPresented: $isPresented
        )
    }

    private func buttons(item: BalanceErrorBottomViewModel.Item) -> [BottomSheetView.ButtonItem] {
        var buttons: [BottomSheetView.ButtonItem] = [
            .init(style: .yellow, title: "button.retry".localized) {
                viewModel.refresh(wallet: item.wallet)
                isPresented = false
            },
        ]

        if let sourceType = item.sourceType {
            buttons.append(
                .init(style: .gray, title: "balance_error.change_source".localized) {
                    isPresented = false

                    switch sourceType {
                    case let .btc(blockchain):
                        Coordinator.shared.present { _ in
                            ThemeNavigationStack {
                                BtcBlockchainSettingsModule.view(blockchain: blockchain)
                            }
                        }
                    case let .evm(blockchain):
                        Coordinator.shared.present { _ in
                            EvmNetworkView(blockchain: blockchain).ignoresSafeArea()
                        }
                    }
                }
            )
        }

        buttons.append(
            .init(style: .transparent, title: "button.report".localized) {
                isPresented = false

                if MFMailComposeViewController.canSendMail() {
                    Coordinator.shared.present { isPresented in
                        MailView(
                            recipient: AppConfig.reportEmail, body: item.error,
                            isPresented: isPresented
                        )
                    }
                } else {
                    CopyHelper.copyAndNotify(value: AppConfig.reportEmail)
                }
            }
        )

        return buttons
    }
}
