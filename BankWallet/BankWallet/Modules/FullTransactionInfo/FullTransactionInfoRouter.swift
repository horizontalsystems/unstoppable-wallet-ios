import UIKit

class FullTransactionInfoRouter {
    weak var viewController: UIViewController?
    private var urlManager: IUrlManager

    init(urlManager: IUrlManager) {
        self.urlManager = urlManager
    }
}


extension FullTransactionInfoRouter: IFullTransactionInfoRouter {

    func open(url: String) {
        urlManager.open(url: url, from: viewController)
    }

}

extension FullTransactionInfoRouter {

    static func module(transactionHash: String, coinCode: String) -> UIViewController {
        let router = FullTransactionInfoRouter(urlManager: App.shared.urlManager)
        let providerFactory = App.shared.fullTransactionInfoProviderFactory

        let interactor = FullTransactionInfoInteractor(transactionProvider: providerFactory.provider(forCoin: coinCode), pasteboardManager: App.shared.pasteboardManager)
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
