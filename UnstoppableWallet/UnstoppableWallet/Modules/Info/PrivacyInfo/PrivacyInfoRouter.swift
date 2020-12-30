import UIKit

class PrivacyInfoRouter {
    weak var viewController: UIViewController?
}

extension PrivacyInfoRouter: IInfoRouter {

    func open(url: String) {
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension PrivacyInfoRouter {

    static func module() -> UIViewController {
        let router = PrivacyInfoRouter()
        let presenter = InfoPresenter(router: router)
        let viewController = InfoViewController(title: "settings_privacy_info.title".localized, delegate: presenter, sectionDataSource: PrivacyInfoSectionDataSource(rowsFactory: InfoRowsFactory()))

        router.viewController = viewController

        return viewController
    }

}
