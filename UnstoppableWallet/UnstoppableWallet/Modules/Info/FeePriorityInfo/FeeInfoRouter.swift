import UIKit

class FeeInfoRouter {
    weak var viewController: UIViewController?
}

extension FeeInfoRouter: IInfoRouter {

    func open(url: String) {
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension FeeInfoRouter {

    static func module() -> UIViewController {
        let router = FeeInfoRouter()
        let presenter = InfoPresenter(router: router)
        let viewController = InfoViewController(title: "send.fee_info.title".localized, delegate: presenter, sectionDataSource: FeeInfoSectionsDataSource(rowsFactory: InfoRowsFactory()))

        router.viewController = viewController

        return viewController
    }

}
