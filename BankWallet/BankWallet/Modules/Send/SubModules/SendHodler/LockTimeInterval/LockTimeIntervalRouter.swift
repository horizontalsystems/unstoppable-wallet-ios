import UIKit
import Hodler

class LockTimeIntervalRouter {
    weak var viewController: UIViewController?
    weak var lockTimeIntervalDelegate: ILockTimeIntervalDelegate?

}

extension LockTimeIntervalRouter: ILockTimeIntervalRouter {

    func dismiss(with lockTimeInterval: HodlerPlugin.LockTimeInterval?) {
        lockTimeIntervalDelegate?.onSelect(lockTimeInterval: lockTimeInterval)
        viewController?.dismiss(animated: true)
    }

}

extension LockTimeIntervalRouter {

    static func module(lockTimeIntervalDelegate: ILockTimeIntervalDelegate?, lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> UIViewController? {
        let router = LockTimeIntervalRouter()
        let presenter = LockTimeIntervalPresenter(router: router, lockTimeInterval: lockTimeInterval)
        let viewController = AlertViewController(delegate: presenter)

        presenter.view = viewController

        router.viewController = viewController
        router.lockTimeIntervalDelegate = lockTimeIntervalDelegate

        return viewController
    }

}
