import UIKit

class RestoreEosRouter {
    weak var viewController: UIViewController?

    private let delegate: ICredentialsCheckDelegate

    init(delegate: ICredentialsCheckDelegate) {
        self.delegate = delegate
    }

}

extension RestoreEosRouter: IRestoreEosRouter {

    func notifyRestored(accountType: AccountType) {
        delegate.didCheck(accountType: accountType)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreEosRouter {

    static func module(presentationMode: RestoreRouter.PresentationMode, proceedMode: RestoreRouter.ProceedMode, delegate: ICredentialsCheckDelegate) -> UIViewController {
        let router = RestoreEosRouter(delegate: delegate)
        let interactor = RestoreEosInteractor(pasteboardManager: App.shared.pasteboardManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestoreEosPresenter(presentationMode: presentationMode, proceedMode: proceedMode, interactor: interactor, router: router, state: RestoreEosPresenterState())
        let viewController = RestoreEosViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
