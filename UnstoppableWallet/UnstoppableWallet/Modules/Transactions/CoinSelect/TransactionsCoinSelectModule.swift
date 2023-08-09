import UIKit
import ThemeKit
import MarketKit

protocol ITransactionsCoinSelectDelegate: AnyObject {
    func didSelect(token: Token?)
}

struct TransactionsCoinSelectModule {

    static func viewController(token: Token?, delegate: ITransactionsCoinSelectDelegate) -> UIViewController {
        let service = TransactionsCoinSelectService(
                token: token,
                walletManager: App.shared.walletManager,
                delegate: delegate
        )
        let viewModel = TransactionsCoinSelectViewModel(service: service)
        let viewController = TransactionsCoinSelectViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
