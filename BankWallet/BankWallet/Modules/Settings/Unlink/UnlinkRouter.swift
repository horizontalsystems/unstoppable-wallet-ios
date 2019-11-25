import UIKit

class UnlinkRouter {
    weak var viewController: UIViewController?
}

extension UnlinkRouter: IUnlinkRouter {

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension UnlinkRouter {

    static func module(account: Account, predefinedAccountType: PredefinedAccountType) -> UIViewController {
        let router = UnlinkRouter()
        let interactor = UnlinkInteractor(accountManager: App.shared.accountManager)
        let presenter = UnlinkPresenter(router: router, interactor: interactor, account: account, predefinedAccountType: predefinedAccountType)
        let viewController = UnlinkViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
