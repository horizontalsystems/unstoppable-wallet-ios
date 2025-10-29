import Combine
import Foundation

class WalletConnectVerificationModel: ObservableObject {
    private let accountManager: AccountManager
    private let cloudBackupManager: CloudBackupManager

    init(accountManager: AccountManager, cloudBackupManager: CloudBackupManager) {
        self.accountManager = accountManager
        self.cloudBackupManager = cloudBackupManager
    }

    func handle(onSuccess: () -> Void) {
        guard let activeAccount = accountManager.activeAccount else {
            presentNoAccount()
            return
        }

        if !activeAccount.type.supportsWalletConnect {
            presentNotSupported(accountType: activeAccount.type) { [weak self] in
                self?.presentSwitchAccount()
            }
            return
        }

        if !activeAccount.backedUp, !cloudBackupManager.backedUp(uniqueId: activeAccount.type.uniqueId()) {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BackupRequiredView.prompt(
                    account: activeAccount,
                    description: "wallet_connect.unbackuped_account.description".localized(activeAccount.name),
                    isPresented: isPresented
                )
            }

            stat(page: .walletConnect, event: .open(page: .backupRequired))
            return
        }

        onSuccess()
    }

    private func presentSwitchAccount() {
        Coordinator.shared.present { _ in
            SwitchAccountView()
        }
    }

    private func presentNoAccount() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView.instance(
                icon: .warning,
                title: "wallet_connect.title".localized,
                items: [
                    .warning(text: "wallet_connect.no_account.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .yellow, title: "button.ok".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ],
                isPresented: isPresented
            )
        }
    }

    private func presentNotSupported(accountType: AccountType, onSwitch: (() -> Void)?) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView.instance(
                icon: .warning,
                title: "wallet_connect.title".localized,
                items: [
                    .warning(text: "wallet_connect.non_supported_account.description".localized(accountType.description)),
                    .buttonGroup(.init(buttons: [
                        .init(style: .yellow, title: "wallet_connect.non_supported_account.switch".localized) {
                            isPresented.wrappedValue = false

                            DispatchQueue.main.async {
                                onSwitch?()
                            }
                        },
                        .init(style: .transparent, title: "button.cancel".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ],
                isPresented: isPresented
            )
        }
    }
}
