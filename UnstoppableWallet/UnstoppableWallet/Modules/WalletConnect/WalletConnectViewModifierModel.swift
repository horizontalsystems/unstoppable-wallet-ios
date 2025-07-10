import Combine

class WalletConnectViewModifierModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager

    @Published var walletConnectNoAccountPresented = false
    @Published var walletConnectNotSupportedAccountType: AccountType?

    func handle(onSuccess: () -> Void) {
        guard let activeAccount = accountManager.activeAccount else {
            walletConnectNoAccountPresented = true
            return
        }

        if !activeAccount.type.supportsWalletConnect {
            walletConnectNotSupportedAccountType = activeAccount.type
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
}
