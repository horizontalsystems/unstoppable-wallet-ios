import UIKit

struct BalanceErrorModule {

    static func viewController(wallet: Wallet, error: Error, sourceViewController: UIViewController?) -> UIViewController {
        let service = BalanceErrorService(
                wallet: wallet,
                error: error,
                adapterManager: App.shared.adapterManager,
                appConfigProvider: App.shared.appConfigProvider,
                btcBlockchainManager: App.shared.btcBlockchainManager,
                evmBlockchainManager: App.shared.evmBlockchainManager
        )
        let viewModel = BalanceErrorViewModel(service: service)
        let viewController = BalanceErrorViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return viewController.toBottomSheet
    }

}
