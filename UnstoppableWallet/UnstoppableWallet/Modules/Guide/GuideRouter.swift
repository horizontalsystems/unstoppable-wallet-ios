import UIKit

class GuideRouter {
    weak var viewController: UIViewController?
}

extension GuideRouter: IGuideRouter {
}

extension GuideRouter {

    static func module(guide: Guide) -> UIViewController {
        let router = GuideRouter()
        let interactor = GuideInteractor()
        let presenter = GuidePresenter(guide: guide, router: router, interactor: interactor)
        let view = GuideViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
