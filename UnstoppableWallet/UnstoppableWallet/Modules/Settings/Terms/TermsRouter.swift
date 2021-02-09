import UIKit

class TermsRouter {

    static func module() -> UIViewController {
        let interactor = TermsInteractor(termsManager: App.shared.termsManager)
        let presenter = TermsPresenter(interactor: interactor)
        let view = TermsViewController(delegate: presenter)

        presenter.view = view

        return view
    }

}
