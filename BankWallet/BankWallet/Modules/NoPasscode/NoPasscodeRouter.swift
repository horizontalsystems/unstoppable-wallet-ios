import UIKit

class NoPasscodeRouter {
    weak var viewController: UIViewController?
}

extension NoPasscodeRouter: INoPasscodeRouter {
}

extension NoPasscodeRouter {

    static func module() -> UIViewController {
        let router = NoPasscodeRouter()
        let interactor = NoPasscodeInteractor()
        let presenter = NoPasscodePresenter(interactor: interactor, router: router)
        let viewController = NoPasscodeViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter
        router.viewController = viewController

        return viewController
    }

}
