import UIKit

class PrivacyRouter {
    weak var viewController: UIViewController?
}

extension PrivacyRouter: IPrivacyRouter {

}

extension PrivacyRouter {

    static func module() -> UIViewController {
        let router = PrivacyRouter()
        let interactor = PrivacyInteractor(initialSyncSettingsManager: App.shared.initialSyncSettingsManager)
        let presenter = PrivacyPresenter(interactor: interactor, router: router)
        let viewController = PrivacyViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
