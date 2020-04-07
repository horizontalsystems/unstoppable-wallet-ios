import UIKit

class RestoreEosRouter {

    static func module(handler: IRestoreAccountTypeHandler) -> UIViewController {
        let interactor = RestoreEosInteractor(pasteboardManager: App.shared.pasteboardManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RestoreEosPresenter(handler: handler, interactor: interactor, state: RestoreEosPresenterState())
        let viewController = RestoreEosViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        return viewController
    }

}
