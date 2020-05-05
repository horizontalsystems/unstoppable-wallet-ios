import UIKit

class PrivacyInfoRouter {
    weak var viewController: UIViewController?
}

extension PrivacyInfoRouter: IPrivacyInfoRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension PrivacyInfoRouter {

    static func module() -> UIViewController {
        let router = PrivacyInfoRouter()
        let presenter = PrivacyInfoPresenter(router: router)
        let viewController = PrivacyInfoViewController(delegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
