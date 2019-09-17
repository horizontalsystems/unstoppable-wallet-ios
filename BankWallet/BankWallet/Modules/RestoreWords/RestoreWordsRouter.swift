import UIKit

class RestoreWordsRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreAccountTypeDelegate

    init(delegate: IRestoreAccountTypeDelegate) {
        self.delegate = delegate
    }

}

extension RestoreWordsRouter: IRestoreWordsRouter {

    func showRestoreOptions(delegate: IRestoreOptionsDelegate) {
        viewController?.navigationController?.pushViewController(RestoreOptionsRouter.module(delegate: delegate), animated: true)
    }

    func notifyRestored(accountType: AccountType, syncMode: SyncMode?) {
        delegate.didRestore(accountType: accountType, syncMode: syncMode)
    }

    func dismissAndNotify(accountType: AccountType, syncMode: SyncMode?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.delegate.didRestore(accountType: accountType, syncMode: syncMode)
        }
    }

    func dismiss() {
        delegate.didCancelRestore()
        viewController?.dismiss(animated: true)
    }

}

extension RestoreWordsRouter {

    static func module(mode: RestoreRouter.PresentationMode, wordsCount: Int, showRestoreOptions: Bool, delegate: IRestoreAccountTypeDelegate) -> UIViewController {
        let router = RestoreWordsRouter(delegate: delegate)
        let presenter = RestoreWordsPresenter(mode: mode, router: router, wordsCount: wordsCount, showRestoreOptions: showRestoreOptions, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let viewController = RestoreWordsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
