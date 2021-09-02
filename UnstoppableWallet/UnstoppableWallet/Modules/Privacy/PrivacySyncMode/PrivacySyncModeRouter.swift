import UIKit
import MarketKit

class PrivacySyncModeRouter {
    weak var viewController: UIViewController?
}

extension PrivacySyncModeRouter: IPrivacySyncModeRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension PrivacySyncModeRouter {

    static func module(platformCoin: PlatformCoin, currentSyncMode: SyncMode, delegate: IPrivacySyncModeDelegate) -> UIViewController {
        let router = PrivacySyncModeRouter()
        let presenter = PrivacySyncModePresenter(platformCoin: platformCoin, currentSyncMode: currentSyncMode, router: router)
        let viewController = PrivacySyncModeViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
