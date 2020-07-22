import UIKit
import SafariServices

class TermsRouter {
    weak var viewController: UIViewController?
}

extension TermsRouter: ITermsRouter {

    func open(link: String) {
        guard let  url = URL(string: link) else {
            return
        }

        viewController?.present(SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration()), animated: true)
    }

}

extension TermsRouter {

    static func module() -> UIViewController {
        let router = TermsRouter()
        let interactor = TermsInteractor(termsManager: App.shared.termsManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = TermsPresenter(router: router, interactor: interactor)
        let view = TermsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
