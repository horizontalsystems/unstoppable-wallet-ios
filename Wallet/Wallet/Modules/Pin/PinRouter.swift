import UIKit

class PinRouter {
    weak var viewController: UIViewController?
}

extension PinRouter: IPinRouter {

}

extension PinRouter {

    static func setPinModule() -> UIViewController {
        let router = PinRouter()
        let interactor = PinInteractor()
        let presenter = PinPresenter(interactor: interactor, router: router)
        let viewController = PinViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
