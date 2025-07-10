import MarketKit
import MessageUI
import SwiftUI

struct BalanceErrorViewModifier: ViewModifier {
    @ObservedObject var viewModel: BalanceErrorViewModifierModel

    @State private var presentedBtcBlockchain: Blockchain?
    @State private var presentedEvmBlockchain: Blockchain?
    @State private var presentedMailError: String?

    func body(content: Content) -> some View {
        content
            .bottomSheet(item: $viewModel.item) { item in
                BottomSheetView(
                    icon: .local(name: "warning_2_24", tint: .themeLucian),
                    title: "balance_error.sync_error".localized,
                    buttons: buttons(item: item),
                    isPresented: Binding(get: { viewModel.item != nil }, set: { if !$0 { viewModel.item = nil } })
                )
            }
            .sheet(item: $presentedBtcBlockchain) { blockchain in
                ThemeNavigationStack { BtcBlockchainSettingsModule.view(blockchain: blockchain) }
            }
            .sheet(item: $presentedEvmBlockchain) { blockchain in
                EvmNetworkView(blockchain: blockchain).ignoresSafeArea()
            }
            .sheet(item: $presentedMailError) { error in
                MailView(recipient: AppConfig.reportEmail, body: error, isPresented: Binding(get: { presentedMailError != nil }, set: { if !$0 { presentedMailError = nil } }))
            }
    }

    private func buttons(item: BalanceErrorViewModifierModel.Item) -> [BottomSheetView.ButtonItem] {
        var buttons: [BottomSheetView.ButtonItem] = [
            .init(style: .yellow, title: "button.retry".localized) {
                viewModel.refresh(wallet: item.wallet)
                viewModel.item = nil
            },
        ]

        if let sourceType = item.sourceType {
            buttons.append(
                .init(style: .gray, title: "balance_error.change_source".localized) {
                    viewModel.item = nil

                    switch sourceType {
                    case let .btc(blockchain): presentedBtcBlockchain = blockchain
                    case let .evm(blockchain): presentedEvmBlockchain = blockchain
                    }
                }
            )
        }

        buttons.append(
            .init(style: .transparent, title: "button.report".localized) {
                viewModel.item = nil

                if MFMailComposeViewController.canSendMail() {
                    presentedMailError = item.error
                } else {
                    CopyHelper.copyAndNotify(value: AppConfig.reportEmail)
                }
            }
        )

        return buttons
    }
}
