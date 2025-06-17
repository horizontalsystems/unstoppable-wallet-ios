import UIKit

enum BalanceErrorModule {
    static func viewController(wallet: Wallet, error: Error, sourceViewController: UIViewController?) -> UIViewController {
        let service = BalanceErrorService(
            wallet: wallet,
            error: error,
            adapterManager: Core.shared.adapterManager,
            btcBlockchainManager: Core.shared.btcBlockchainManager,
            evmBlockchainManager: Core.shared.evmBlockchainManager
        )
        let viewModel = BalanceErrorViewModel(service: service)
        let viewController = BalanceErrorViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return viewController.toBottomSheet
    }
}
