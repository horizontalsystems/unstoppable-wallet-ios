import UIKit

class GuidesRouter {
    weak var viewController: UIViewController?
}

extension GuidesRouter: IGuidesRouter {

    func show(guide: Guide) {
        guard let module = GuideRouter.module(guide: guide) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

}

extension GuidesRouter {

    static func module() -> UIViewController? {
        let router = GuidesRouter()
        let interactor = GuidesInteractor(appConfigProvider: App.shared.appConfigProvider, guidesManager: App.shared.guidesManager)

        guard let presenter = GuidesPresenter(router: router, interactor: interactor) else {
            return nil
        }

        let view = GuidesViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
