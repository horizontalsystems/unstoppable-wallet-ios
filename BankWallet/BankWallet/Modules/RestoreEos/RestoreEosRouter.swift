import UIKit

class RestoreEosRouter {

    weak var viewController: UIViewController?

    private let delegate: IRestoreAccountTypeDelegate

    init(delegate: IRestoreAccountTypeDelegate) {
        self.delegate = delegate
    }

    static func module(mode: RestoreRouter.PresentationMode, delegate: IRestoreAccountTypeDelegate) -> UIViewController {
        let router = RestoreEosRouter(delegate: delegate)
        let interactor = RestoreEosInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = RestoreEosPresenter(mode: mode, interactor: interactor, router: router, state: RestoreEosPresenterState())
        let viewController = RestoreEosViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

extension RestoreEosRouter: IRestoreEosRouter {

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}