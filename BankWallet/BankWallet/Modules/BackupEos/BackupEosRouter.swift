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
        let presenter = BackupEosPresenter(router: router, account: account, activePrivateKey: activePrivateKey)
        let viewController = BackupEosViewController(delegate: presenter)

        router.viewController = viewController

        return viewController
    }

}
