import UIKit

enum WalletConnectAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        let walletConnectWorkerService = WalletConnectAppShowService(
            walletConnectManager: Core.shared.walletConnectSessionManager,
            cloudAccountBackupManager: Core.shared.cloudBackupManager,
            accountManager: Core.shared.accountManager,
            lockManager: Core.shared.lockManager
        )
        let walletConnectWorkerViewModel = WalletConnectAppShowViewModel(service: walletConnectWorkerService)

        let viewController = WalletConnectAppShowView(
            viewModel: walletConnectWorkerViewModel,
            requestViewFactory: Core.shared.walletConnectRequestHandler
        )
        viewController.parentViewController = parentViewController

        return viewController
    }
}
