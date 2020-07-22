import UIKit

class TermsRouter {
    weak var viewController: UIViewController?
}

extension TermsRouter: ITermsRouter {
}

extension TermsRouter {

    static func module() -> UIViewController {
        let router = TermsRouter()
        let interactor = TermsInteractor(termsManager: App.shared.termsManager)
        let presenter = TermsPresenter(router: router, interactor: interactor)
        let view = TermsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
