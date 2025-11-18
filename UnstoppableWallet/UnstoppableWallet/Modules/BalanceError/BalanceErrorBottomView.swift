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
            items: [
                .title(icon: ThemeImage.error, title: "balance_error.sync_error".localized),
                .text(text: viewModel.item.sourceType != nil ? "balance_error.sync_error.description.with_source".localized : "balance_error.sync_error.description.without_source".localized),
                .buttonGroup(.init(buttons: buttons(item: viewModel.item))),
            ],
        )
    }

    private func buttons(item: BalanceErrorBottomViewModel.Item) -> [ButtonGroupViewModel.ButtonItem] {
        var buttons: [ButtonGroupViewModel.ButtonItem] = [
            .init(style: .gray, title: "button.retry".localized) {
                viewModel.refresh(wallet: item.wallet)
                isPresented = false
            },
        ]

        if let sourceType = item.sourceType {
            buttons.append(
                .init(style: .transparent, title: "balance_error.change_source".localized) {
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
                    case let .monero(blockchain):
                        Coordinator.shared.present { _ in
                            MoneroNetworkView(blockchain: blockchain).ignoresSafeArea()
                        }
                    }
                }
            )
        }

        return buttons
    }
}
