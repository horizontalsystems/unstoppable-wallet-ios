import UIKit
import Hodler

class SendHodlerRouter {
    weak var viewController: UIViewController?
}

extension SendHodlerRouter {

    static func module() -> (UIView, ISendHodlerModule, ISendSubRouter) {
        let router = SendHodlerRouter()
        let presenter = SendHodlerPresenter(router: router)
        let view = SendHodlerView(delegate: presenter)

        presenter.view = view

        return (view, presenter, router)
    }

}

extension SendHodlerRouter: ISendHodlerRouter {

    func openLockTimeIntervals(selected: HodlerPlugin.LockTimeInterval?, delegate: ISendHodlerLockTimeIntervalDelegate) {
        let module = SendHodlerLockTimeIntervalRouter.module(selectedLockTimeInterval: selected, delegate: delegate)
        viewController?.present(module, animated: true)
    }

}

extension SendHodlerRouter: ISendSubRouter {
}
