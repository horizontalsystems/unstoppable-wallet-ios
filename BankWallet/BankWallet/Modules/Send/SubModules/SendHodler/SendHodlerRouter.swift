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

    func openLockTimeIntervals(selected: HodlerPlugin.LockTimeInterval?, lockTimeIntervalDelegate: ILockTimeIntervalDelegate) {
        LockTimeIntervalRouter.module(lockTimeIntervalDelegate: lockTimeIntervalDelegate, lockTimeInterval: selected).map { viewController in
            self.viewController?.present(viewController, animated: true)
        }
    }

}

extension SendHodlerRouter: ISendSubRouter {
}
