import Combine
import Foundation
import TronKit

class TronWalletTokenViewModel: ObservableObject {
    private let tronKit: TronKit.Kit
    private var cancellables = Set<AnyCancellable>()

    private var hasAppeared = false
    @Published var accountActive: Bool

    init(tronKit: TronKit.Kit) {
        self.tronKit = tronKit
        accountActive = tronKit.accountActive

        tronKit.trxBalancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)
    }

    private func sync() {
        let newAccountActive = tronKit.accountActive

        if newAccountActive != accountActive {
            accountActive = newAccountActive
        }
    }

    func onFirstAppear() {
        guard !hasAppeared else {
            return
        }

        hasAppeared = true

        if !accountActive {
            showPopup()
        }
    }

    private func showPopup() {
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
                    ],
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
