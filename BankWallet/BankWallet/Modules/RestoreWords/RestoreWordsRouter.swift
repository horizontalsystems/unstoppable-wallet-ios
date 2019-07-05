import UIKit

class RestoreWordsRouter {
    weak var viewController: UIViewController?
    weak var delegate: IRestoreDelegate?
    weak var syncModeDelegate: ISyncModeDelegate?
}

extension RestoreWordsRouter: IRestoreWordsRouter {

    func showSyncMode() {
        viewController?.navigationController?.pushViewController(SyncModeRouter.module(delegate: syncModeDelegate), animated: true)
    }

    func notifyRestored(accountType: AccountType, syncMode: SyncMode) {
        delegate?.didRestore(accountType: accountType, syncMode: syncMode)
    }

}

extension RestoreWordsRouter {

    static func module(delegate: IRestoreDelegate?) -> UIViewController {
        let router = RestoreWordsRouter()
        let interactor = RestoreWordsInteractor(wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestoreWordsPresenter(interactor: interactor, router: router)
        let viewController = RestoreWordsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.delegate = delegate
        router.syncModeDelegate = interactor

        return viewController
    }

}
