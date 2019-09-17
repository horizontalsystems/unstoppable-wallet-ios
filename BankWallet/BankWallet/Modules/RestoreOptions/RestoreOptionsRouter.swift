import UIKit

class RestoreOptionsRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreOptionsDelegate

    init(delegate: IRestoreOptionsDelegate) {
        self.delegate = delegate
    }

}

extension RestoreOptionsRouter: IRestoreOptionsRouter {

    func notifyDelegate(isFast: Bool) {
        delegate.onSelectRestoreOptions(isFast: isFast)
    }

}

extension RestoreOptionsRouter {

    static func module(delegate: IRestoreOptionsDelegate) -> UIViewController {
        let router = RestoreOptionsRouter(delegate: delegate)
        let presenter = RestoreOptionsPresenter(router: router)
        let viewController = RestoreOptionsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
