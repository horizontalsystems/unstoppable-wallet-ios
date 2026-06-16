import Combine
import Foundation
import MarketKit

class TronWalletTokenViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    private var hasAppeared = false
    private let watchAccount: Bool
    @Published var accountActive: Bool

    init(adapter: BaseTronAdapter, wallet: Wallet) {
        watchAccount = wallet.account.watchAccount
        accountActive = adapter.effectiveAccountActive

        adapter.effectiveAccountActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in self?.accountActive = active }
            .store(in: &cancellables)
    }

    func onFirstAppear() {
        guard !hasAppeared else {
            return
        }

        hasAppeared = true

        if !accountActive, !watchAccount {
            showPopup()
        }
    }

    func showPopup() {
        DispatchQueue.main.async {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.warning, title: "deposit.not_active.title".localized),
                        .text(text: "deposit.not_active.tron_description".localized),
                        .buttonGroup(.init(buttons: [
                            .init(style: .gray, title: "deposit.not_active.view_address".localized, action: { [weak self] in
                                isPresented.wrappedValue = false
                                self?.showAddressView()
                            }),
                        ])),
                    ]
                )
            }
        }
    }

    @MainActor
    private func showAddressView() {
        guard let account = Core.shared.accountManager.activeAccount else {
            Core.shared.logger.log(level: .error, message: "Can't found active account")
            return
        }

        guard let trxToken = try? Core.shared.marketKit.token(query: .init(blockchainType: .tron, tokenType: .native)) else {
            Core.shared.logger.log(level: .error, message: "Can't found TRX in MarketKit")
            return
        }

        Coordinator.shared.present { _ in
            EmptyThemeNavigationStack { path in
                ReceiveModule.view(token: trxToken, account: account, path: path, onDismiss: nil)
            }
        }
    }
}
