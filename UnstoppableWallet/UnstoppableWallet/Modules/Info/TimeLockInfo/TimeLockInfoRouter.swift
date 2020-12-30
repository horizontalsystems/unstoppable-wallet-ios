import UIKit

class TimeLockInfoRouter {
    weak var viewController: UIViewController?

    static func module() -> UIViewController {
        let router = TimeLockInfoRouter()
        let presenter = InfoPresenter(router: router)
        let viewController = InfoViewController(title: "lock_info.title".localized, delegate: presenter, sectionDataSource: TimeLockSectionDataSource(rowsFactory: InfoRowsFactory()))

        router.viewController = viewController

        return viewController
    }

}

extension TimeLockInfoRouter: IInfoRouter {

    func open(url: String) {
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}
