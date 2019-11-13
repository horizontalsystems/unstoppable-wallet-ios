import UIKit

class DebugRouter {
}

extension DebugRouter: IDebugRouter {
}

extension DebugRouter {

    static func module() -> UIViewController {
        let interactor = DebugInteractor(appManager: App.shared.appManager, debugBackgroundManager: App.shared.debugLogger, pasteboardManager: App.shared.pasteboardManager)
        let presenter = DebugPresenter(interactor: interactor)
        let viewController = DebugViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
