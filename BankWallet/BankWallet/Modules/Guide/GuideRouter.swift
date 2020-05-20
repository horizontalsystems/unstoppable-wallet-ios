import UIKit

class GuideRouter {
    weak var viewController: UIViewController?
}

extension GuideRouter: IGuideRouter {
}

extension GuideRouter {

    static func module(url: String) -> UIViewController {
        let router = GuideRouter()
        let interactor = GuideInteractor()
        let presenter = GuidePresenter(url: url, router: router, interactor: interactor)
        let view = GuideViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
