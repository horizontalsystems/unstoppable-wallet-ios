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

    static func module(coinTitle: String, coinIconName: String, coinType: CoinType, currentSyncMode: SyncMode, delegate: IPrivacySyncModeDelegate) -> UIViewController {
        let router = PrivacySyncModeRouter()
        let presenter = PrivacySyncModePresenter(coinTitle: coinTitle, coinIconName: coinIconName, coinType: coinType, currentSyncMode: currentSyncMode, router: router)
        let viewController = PrivacySyncModeViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
