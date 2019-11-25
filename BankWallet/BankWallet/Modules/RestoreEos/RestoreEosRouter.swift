import UIKit

class RestoreEosRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreAccountTypeDelegate

    init(delegate: IRestoreAccountTypeDelegate) {
        self.delegate = delegate
    }

}

extension RestoreEosRouter: IRestoreEosRouter {

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

extension RestoreEosRouter {

    static func module(mode: RestoreRouter.PresentationMode, delegate: IRestoreAccountTypeDelegate) -> UIViewController {
        let router = RestoreEosRouter(delegate: delegate)
        let interactor = RestoreEosInteractor(pasteboardManager: App.shared.pasteboardManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestoreEosPresenter(mode: mode, interactor: interactor, router: router, state: RestoreEosPresenterState())
        let viewController = RestoreEosViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
