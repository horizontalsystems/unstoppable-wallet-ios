import UIKit

class AppStatusRouter {
}

extension AppStatusRouter {

    static func module() -> UIViewController {
        let interactor = AppStatusInteractor(appStatusManager: App.shared.appStatusManager, pasteboardManager: App.shared.pasteboardManager)
        let presenter = AppStatusPresenter(interactor: interactor)
        let viewController = AppStatusViewController(delegate: presenter)

        presenter.view = viewController

        return viewController
    }

}
