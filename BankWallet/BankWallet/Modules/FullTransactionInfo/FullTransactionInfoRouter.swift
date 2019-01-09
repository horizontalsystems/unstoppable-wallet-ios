import UIKit

class FullTransactionInfoRouter {
    weak var viewController: UIViewController?
}


extension FullTransactionInfoRouter: IFullTransactionInfoRouter {
}

extension FullTransactionInfoRouter {

    static func module(transactionHash: String, coinCode: String) -> UIViewController {
        let router = FullTransactionInfoRouter()
        let providerFactory = App.shared.fullTransactionInfoProviderFactory

        let interactor = FullTransactionInfoInteractor(transactionProvider: providerFactory.provider(forCoin: coinCode))
        let state = FullTransactionInfoState(transactionHash: transactionHash)
        let presenter = FullTransactionInfoPresenter(interactor: interactor, router: router, state: state)
        let viewController = FullTransactionInfoViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.tintColor = AppTheme.navigationBarTintColor
        navigationController.navigationBar.barStyle = AppTheme.navigationBarStyle

        return navigationController
    }

}
