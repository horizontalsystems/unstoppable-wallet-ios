import UIKit

class RestoreWordsRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreDelegate

    init(delegate: IRestoreDelegate) {
        self.delegate = delegate
    }

}

extension RestoreWordsRouter: IRestoreWordsRouter {

    func showSyncMode(delegate: ISyncModeDelegate) {
        viewController?.navigationController?.pushViewController(SyncModeRouter.module(delegate: delegate), animated: true)
    }

    func notifyRestored(accountType: AccountType, syncMode: SyncMode) {
        delegate.didRestore(accountType: accountType, syncMode: syncMode)
    }

    func dismissAndNotify(accountType: AccountType, syncMode: SyncMode) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.delegate.didRestore(accountType: accountType, syncMode: syncMode)
        }
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreWordsRouter {

    static func module(mode: RestoreRouter.PresentationMode, delegate: IRestoreDelegate) -> UIViewController {
        let router = RestoreWordsRouter(delegate: delegate)
        let presenter = RestoreWordsPresenter(mode: mode, router: router, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let viewController = RestoreWordsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
