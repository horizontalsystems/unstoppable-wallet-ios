import SwiftUI

struct WalletConnectViewModifier: ViewModifier {
    @ObservedObject var viewModel: WalletConnectViewModifierModel

    @State private var switchAccountPresented = false

    func body(content: Content) -> some View {
        content
            .bottomSheet(isPresented: $switchAccountPresented) {
                SwitchAccountView()
            }
            .bottomSheet(isPresented: $viewModel.walletConnectNoAccountPresented) {
                BottomSheetView(
                    icon: .local(name: "wallet_connect_24", tint: .themeJacob),
                    title: "wallet_connect.title".localized,
                    items: [
                        .highlightedDescription(text: "wallet_connect.no_account.description".localized),
                    ],
                    buttons: [
                        .init(style: .yellow, title: "button.ok".localized) {
                            viewModel.walletConnectNoAccountPresented = false
                        },
                    ],
                    isPresented: $viewModel.walletConnectNoAccountPresented
                )
            }
            .bottomSheet(item: $viewModel.walletConnectNotSupportedAccountType) { accountType in
                BottomSheetView(
                    icon: .local(name: "wallet_connect_24", tint: .themeJacob),
                    title: "wallet_connect.title".localized,
                    items: [
                        .highlightedDescription(text: "wallet_connect.non_supported_account.description".localized(accountType.description)),
                    ],
                    buttons: [
                        .init(style: .yellow, title: "wallet_connect.non_supported_account.switch".localized) {
                            viewModel.walletConnectNotSupportedAccountType = nil

                            DispatchQueue.main.async {
                                switchAccountPresented = true
                            }
                        },
                        .init(style: .transparent, title: "button.cancel".localized) {
                            viewModel.walletConnectNotSupportedAccountType = nil
                        },
                    ],
                    isPresented: Binding(get: { viewModel.walletConnectNotSupportedAccountType != nil }, set: { if !$0 { viewModel.walletConnectNotSupportedAccountType = nil } })
                )
            }
    }
}
