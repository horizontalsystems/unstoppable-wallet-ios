import UIKit
import ThemeKit
import MarketKit

protocol ITransactionsCoinSelectDelegate: AnyObject {
    func didSelect(configuredToken: ConfiguredToken?)
}

struct TransactionsCoinSelectModule {

    static func viewController(configuredToken: ConfiguredToken?, delegate: ITransactionsCoinSelectDelegate) -> UIViewController {
        let service = TransactionsCoinSelectService(
                configuredToken: configuredToken,
                walletManager: App.shared.walletManager,
                delegate: delegate
        )
        let viewModel = TransactionsCoinSelectViewModel(service: service)
        let viewController = TransactionsCoinSelectViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
