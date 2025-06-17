import Combine

class WalletConnectViewModifierModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let cloudBackupManager = Core.shared.cloudBackupManager

    @Published var walletConnectNoAccountPresented = false
    @Published var walletConnectNotSupportedAccountType: AccountType?
    @Published var walletConnectBackupRequiredAccount: Account?
    @Published var walletConnectPresented = false

    func handle() {
        guard let activeAccount = accountManager.activeAccount else {
            walletConnectNoAccountPresented = true
            return
        }

        if !activeAccount.type.supportsWalletConnect {
            walletConnectNotSupportedAccountType = activeAccount.type
            return
        }

        if !activeAccount.backedUp, !cloudBackupManager.backedUp(uniqueId: activeAccount.type.uniqueId()) {
            walletConnectBackupRequiredAccount = activeAccount
            return
        }

        walletConnectPresented = true
    }
}
