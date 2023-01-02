import UIKit

struct BalanceErrorModule {

    static func viewController(wallet: Wallet, error: Error, sourceViewController: UIViewController?) -> UIViewController {
        let service = BalanceErrorService(
                wallet: wallet,
                error: error,
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.adapterManager,
                appConfigProvider: App.shared.appConfigProvider,
                evmBlockchainManager: App.shared.evmBlockchainManager
        )
        let viewModel = BalanceErrorViewModel(service: service)
        let viewController = BalanceErrorViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return viewController.toBottomSheet
    }

}
