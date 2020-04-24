import UIKit
import ThemeKit

class SortTypeRouter {

    static func module() -> UIViewController {
        let router = AlertRouter()
        let interactor = SortTypeInteractor(sortTypeManager: App.shared.sortTypeManager)
        let presenter = SortTypePresenter(interactor: interactor, router: router)

        let viewController = SortTypeViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toAlert
    }

}
