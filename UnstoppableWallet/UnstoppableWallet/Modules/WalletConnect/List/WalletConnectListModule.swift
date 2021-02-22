import UIKit

class WalletConnectListModule {

    static func viewController() -> UIViewController {
        let service = WalletConnectListService(
                predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager,
                sessionManager: App.shared.walletConnectSessionManager
        )

        let viewModel = WalletConnectListViewModel(service: service)
        return WalletConnectListViewController(viewModel: viewModel)
    }

}
