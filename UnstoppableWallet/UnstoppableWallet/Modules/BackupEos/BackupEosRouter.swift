import UIKit

class BackupEosRouter {
    weak var viewController: UIViewController?
    private let delegate: IBackupDelegate

    init(delegate: IBackupDelegate) {
        self.delegate = delegate
    }
}

extension BackupEosRouter: IBackupEosRouter {

    func notifyClosed() {
        delegate.didClose()
    }

}

extension BackupEosRouter {

    static func module(delegate: IBackupDelegate, account: String, activePrivateKey: String) -> UIViewController {
        let router = BackupEosRouter(delegate: delegate)
        let interactor = BackupEosInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = BackupEosPresenter(interactor: interactor, router: router, account: account, activePrivateKey: activePrivateKey)
        let viewController = BackupEosViewController(delegate: presenter)

        router.viewController = viewController
        presenter.view = viewController

        return viewController
    }

}
