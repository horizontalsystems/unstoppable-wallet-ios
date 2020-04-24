import UIKit
import Hodler

class SendHodlerLockTimeIntervalRouter {
    weak var viewController: UIViewController?

    private weak var delegate: ISendHodlerLockTimeIntervalDelegate?

    init(delegate: ISendHodlerLockTimeIntervalDelegate) {
        self.delegate = delegate
    }

}

extension SendHodlerLockTimeIntervalRouter: ISendHodlerLockTimeIntervalRouter {

    func notifyAndClose(lockTimeInterval: HodlerPlugin.LockTimeInterval?) {
        delegate?.onSelect(lockTimeInterval: lockTimeInterval)
        viewController?.dismiss(animated: true)
    }

}

extension SendHodlerLockTimeIntervalRouter {

    static func module(selectedLockTimeInterval: HodlerPlugin.LockTimeInterval?, delegate: ISendHodlerLockTimeIntervalDelegate) -> UIViewController {
        let router = SendHodlerLockTimeIntervalRouter(delegate: delegate)
        let presenter = SendHodlerLockTimeIntervalPresenter(selectedLockTimeInterval: selectedLockTimeInterval, router: router)
        let viewController = SendHodlerLockTimeIntervalViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toAlert
    }

}
