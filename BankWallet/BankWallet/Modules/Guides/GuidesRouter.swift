import UIKit

class GuidesRouter {
    weak var viewController: UIViewController?
}

extension GuidesRouter: IGuidesRouter {

    func showGuide(url: String) {
        let module = GuideRouter.module(url: url)
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

}

extension GuidesRouter {

    static func module() -> UIViewController {
        let router = GuidesRouter()
        let interactor = GuidesInteractor()
        let presenter = GuidesPresenter(router: router, interactor: interactor)
        let view = GuidesViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
