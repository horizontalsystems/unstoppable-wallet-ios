import UIKit
import ThemeKit

class AddErc20TokenRouter {
    weak var viewController: UIViewController?
}

extension AddErc20TokenRouter: IAddErc20TokenRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension AddErc20TokenRouter {

    static func module() -> UIViewController {
        let router = AddErc20TokenRouter()
        let interactor = AddErc20TokenInteractor(coinManager: App.shared.coinManager, pasteboardManager: App.shared.pasteboardManager, erc20ContractInfoProvider: App.shared.erc20ContractInfoProvider)
        let presenter = AddErc20TokenPresenter(interactor: interactor, router: router)
        let viewController = AddErc20TokenViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}
