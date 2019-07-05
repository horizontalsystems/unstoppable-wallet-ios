import UIKit

class SyncModeRouter {
    weak var viewController: UIViewController?

    private let delegate: ISyncModeDelegate

    init(delegate: ISyncModeDelegate) {
        self.delegate = delegate
    }

}

extension SyncModeRouter: ISyncModeRouter {

    func notifyDelegate(isFast: Bool) {
        delegate.onSelectSyncMode(isFast: isFast)
    }

}

extension SyncModeRouter {

    static func module(delegate: ISyncModeDelegate) -> UIViewController {
        let router = SyncModeRouter(delegate: delegate)
        let presenter = SyncModePresenter(router: router)
        let viewController = SyncModeViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
