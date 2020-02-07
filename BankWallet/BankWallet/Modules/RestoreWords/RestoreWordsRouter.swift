import UIKit
import ThemeKit

class RestoreWordsRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreAccountTypeDelegate

    init(delegate: IRestoreAccountTypeDelegate) {
        self.delegate = delegate
    }

}

extension RestoreWordsRouter: IRestoreWordsRouter {

    func notifyRestored(accountType: AccountType) {
        delegate.didRestore(accountType: accountType)
    }

    func dismissAndNotify(accountType: AccountType) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.delegate.didRestore(accountType: accountType)
        }
    }

    func dismiss() {
        delegate.didCancelRestore()
        viewController?.dismiss(animated: true)
    }

}

extension RestoreWordsRouter {

    static func module(mode: RestoreRouter.PresentationMode, wordsCount: Int, delegate: IRestoreAccountTypeDelegate) -> UIViewController {
        let router = RestoreWordsRouter(delegate: delegate)
        let presenter = RestoreWordsPresenter(mode: mode, router: router, wordsCount: wordsCount, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let viewController = RestoreWordsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
