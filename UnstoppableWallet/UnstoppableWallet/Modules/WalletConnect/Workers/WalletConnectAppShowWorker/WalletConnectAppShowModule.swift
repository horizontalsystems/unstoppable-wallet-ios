import UIKit

class WalletConnectAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        let walletConnectWorkerService = WalletConnectAppShowService(
            walletConnectManager: App.shared.walletConnectSessionManager,
            cloudAccountBackupManager: App.shared.cloudBackupManager,
            accountManager: App.shared.accountManager,
            pinKit: App.shared.pinKit
        )
        let walletConnectWorkerViewModel = WalletConnectAppShowViewModel(service: walletConnectWorkerService)

        let viewController = WalletConnectAppShowView(viewModel: walletConnectWorkerViewModel)
        viewController.parentViewController = parentViewController

        return viewController
    }
}
