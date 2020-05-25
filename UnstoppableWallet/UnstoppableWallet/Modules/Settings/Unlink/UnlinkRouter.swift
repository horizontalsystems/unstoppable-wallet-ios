import UIKit

class UnlinkRouter {
    weak var viewController: UIViewController?
}

extension UnlinkRouter: IUnlinkRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension UnlinkRouter {

    static func module(account: Account, predefinedAccountType: PredefinedAccountType) -> UIViewController {
        let router = UnlinkRouter()
        let interactor = UnlinkInteractor(accountManager: App.shared.accountManager)
        let presenter = UnlinkPresenter(account: account, predefinedAccountType: predefinedAccountType, router: router, interactor: interactor)
        let viewController = UnlinkViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
