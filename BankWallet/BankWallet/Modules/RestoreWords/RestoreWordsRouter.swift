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

}

extension RestoreWordsRouter {

    static func module(delegate: IRestoreDelegate) -> UIViewController {
        let router = RestoreWordsRouter(delegate: delegate)
        let interactor = RestoreWordsInteractor(wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestoreWordsPresenter(interactor: interactor, router: router)
        let viewController = RestoreWordsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
