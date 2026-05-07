import UIKit

enum WalletConnectHandlerModule {
    static func handler(
        walletConnectManager: WalletConnectSessionManager,
        walletConnectRequestHandler _: WalletConnectRequestChain,
        cloudAccountBackupManager: CloudBackupManager,
        accountManager: AccountManager,
        lockManager: LockManager
    ) -> IEventHandler {
        let walletConnectWorkerService = WalletConnectEventHandlerService(
            walletConnectManager: walletConnectManager,
            cloudAccountBackupManager: cloudAccountBackupManager,
            accountManager: accountManager,
            lockManager: lockManager
        )
        let walletConnectEventHandlerModel = WalletConnectEventHandlerModel(service: walletConnectWorkerService)

        let handler = WalletConnectEventHandler(
            viewModel: walletConnectEventHandlerModel
        )

        return handler
    }
}
