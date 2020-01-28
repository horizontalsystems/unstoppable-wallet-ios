import UIKit

class RestoreWordsRouter {
    weak var viewController: UIViewController?

    weak private var delegate: ICredentialsCheckDelegate?

    init(delegate: ICredentialsCheckDelegate) {
        self.delegate = delegate
    }

}

extension RestoreWordsRouter: IRestoreWordsRouter {

    func notifyChecked(accountType: AccountType) {
        delegate?.didCheck(accountType: accountType)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreWordsRouter {

    static func module(presentationMode: RestoreRouter.PresentationMode, proceedMode: RestoreRouter.ProceedMode, wordsCount: Int, delegate: ICredentialsCheckDelegate) -> UIViewController {
        let router = RestoreWordsRouter(delegate: delegate)
        let presenter = RestoreWordsPresenter(presentationMode: presentationMode, proceedMode: proceedMode, router: router, wordsCount: wordsCount, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let viewController = RestoreWordsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
