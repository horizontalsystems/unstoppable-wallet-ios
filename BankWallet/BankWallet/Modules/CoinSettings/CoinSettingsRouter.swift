import UIKit

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

}

extension CoinSettingsRouter {

    static func module(coin: Coin, coinSettings: CoinSettings, delegate: ICoinSettingsDelegate) -> UIViewController {
        let router = CoinSettingsRouter(delegate: delegate)
        let presenter = CoinSettingsPresenter(coin: coin, coinSettings: coinSettings, router: router)
        let viewController = CoinSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

}
