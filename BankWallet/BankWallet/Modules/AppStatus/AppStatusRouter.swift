import UIKit

class AppStatusRouter {
}

extension AppStatusRouter {

    static func module() -> UIViewController {
        let interactor = AppStatusInteractor(appStatusManager: AppStatusManager(), pasteboardManager: App.shared.pasteboardManager)
        let presenter = AppStatusPresenter(interactor: interactor)
        let viewController = DebugViewController(delegate: presenter)

        presenter.view = viewController

        return viewController
    }

}
