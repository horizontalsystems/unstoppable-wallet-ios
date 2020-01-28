import UIKit
import ThemeKit

class CoinSettingsRouter {
    weak var viewController: UIViewController?

    private let delegate: ICoinSettingsDelegate

    init(delegate: ICoinSettingsDelegate) {
        self.delegate = delegate
    }

}

extension CoinSettingsRouter: ICoinSettingsRouter {

    func notifySelectedAndClose(coinSettings: CoinSettings, coin: Coin) {
        delegate.onSelect(coinSettings: coinSettings, coin: coin)
        viewController?.dismiss(animated: true)
    }

    func notifyCancelledAndClose() {
        delegate.onCancelSelectingCoinSettings()
        viewController?.dismiss(animated: true)
    }

    func open(url: String) {
        guard let url = URL(string: url) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

extension CoinSettingsRouter {

    static func module(coin: Coin, coinSettings: CoinSettings, mode: CoinSettingsModule.Mode, delegate: ICoinSettingsDelegate) -> UIViewController {
        let router = CoinSettingsRouter(delegate: delegate)
        let presenter = CoinSettingsPresenter(coin: coin, coinSettings: coinSettings, router: router)
        let viewController = CoinSettingsViewController(delegate: presenter, mode: mode)

        presenter.view = viewController
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}
