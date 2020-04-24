import UIKit
import ThemeKit

class SortTypeRouter {
    weak var viewController: UIViewController?
}

extension SortTypeRouter: ISortTypeRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension SortTypeRouter {

    static func module() -> UIViewController {
        let router = SortTypeRouter()
        let interactor = SortTypeInteractor(sortTypeManager: App.shared.sortTypeManager)
        let presenter = SortTypePresenter(interactor: interactor, router: router)

        let viewController = SortTypeViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toAlert
    }

}
