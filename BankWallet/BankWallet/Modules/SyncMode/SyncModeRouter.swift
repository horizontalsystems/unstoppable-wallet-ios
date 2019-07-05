import UIKit

class SyncModeRouter {
    weak var viewController: UIViewController?
    weak var delegate: ISyncModeDelegate?
}

extension SyncModeRouter: ISyncModeRouter {

    func notifyDelegate(isFast: Bool) {
        delegate?.onSelectSyncMode(isFast: isFast)
    }

}

extension SyncModeRouter {

    static func module(delegate: ISyncModeDelegate?) -> UIViewController {
        let router = SyncModeRouter()
        let interactor = SyncModeInteractor()
        let presenter = SyncModePresenter(interactor: interactor, router: router)
        let viewController = SyncModeViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.delegate = delegate

        return viewController
    }

}
