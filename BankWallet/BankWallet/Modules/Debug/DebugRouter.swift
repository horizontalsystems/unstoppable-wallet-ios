import UIKit

class DebugRouter {
}

extension DebugRouter: IDebugRouter {
}

extension DebugRouter {

    static func module() -> UIViewController {
        let router = DebugRouter()

        let debugBackgroundManager = App.shared.debugBackgroundLogger
        let interactor = DebugInteractor(appManager: App.shared.appManager, debugBackgroundManager: debugBackgroundManager, pasteboardManager: App.shared.pasteboardManager)
        let presenter = DebugPresenter(interactor: interactor, router: router)
        let viewController = DebugViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
