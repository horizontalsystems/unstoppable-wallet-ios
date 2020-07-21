import UIKit

class GuidesRouter {
    weak var viewController: UIViewController?
}

extension GuidesRouter: IGuidesRouter {

    func show(guideUrl: URL) {
        let module = GuideRouter.module(guideUrl: guideUrl)
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

}

extension GuidesRouter {

    static func module() -> UIViewController {
        let router = GuidesRouter()
        let interactor = GuidesInteractor(appConfigProvider: App.shared.appConfigProvider, guidesManager: App.shared.guidesManager)
        let presenter = GuidesPresenter(router: router, interactor: interactor)
        let view = GuidesViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
