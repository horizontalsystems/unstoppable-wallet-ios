import UIKit

class BackupConfirmationRouter {
    private let delegate: IBackupConfirmationDelegate

    init(delegate: IBackupConfirmationDelegate) {
        self.delegate = delegate
    }
}

extension BackupConfirmationRouter: IBackupConfirmationRouter {

    func notifyDidValidate() {
        delegate.didValidate()
    }

}

extension BackupConfirmationRouter {

    static func module(delegate: IBackupConfirmationDelegate, words: [String]) -> UIViewController {
        let router = BackupConfirmationRouter(delegate: delegate)
        let interactor = BackupConfirmationInteractor(randomManager: App.shared.randomManager)
        let presenter = BackupConfirmationPresenter(interactor: interactor, router: router, words: words)

        let viewController = BackupConfirmationController(delegate: presenter)

        presenter.view = viewController

        return viewController
    }

}
