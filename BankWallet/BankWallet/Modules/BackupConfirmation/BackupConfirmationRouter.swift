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

    static func module(delegate: IBackupConfirmationDelegate, words: [String], predefinedAccountType: PredefinedAccountType) -> UIViewController {
        let router = BackupConfirmationRouter(delegate: delegate)
        let interactor = BackupConfirmationInteractor(randomManager: RandomManager(), wordsValidator: WordsValidator(), appManager: App.shared.appManager)
        let presenter = BackupConfirmationPresenter(interactor: interactor, router: router, words: words, predefinedAccountType: predefinedAccountType)

        let viewController = BackupConfirmationController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        return viewController
    }

}
