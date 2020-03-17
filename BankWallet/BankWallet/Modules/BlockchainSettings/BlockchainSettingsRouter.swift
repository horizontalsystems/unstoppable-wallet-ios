import UIKit
import ThemeKit

class BlockchainSettingsRouter {
    weak var viewController: UIViewController?
}

extension BlockchainSettingsRouter: IBlockchainSettingsRouter {

    func open(url: String) {
        guard let url = URL(string: url) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

extension BlockchainSettingsRouter {

    static func module(coin: Coin, settings: BlockchainSetting, delegate: IBlockchainSettingsUpdateDelegate) -> UIViewController {
        let router = BlockchainSettingsRouter()
        let interactor = BlockchainSettingsInteractor(coinSettingsManager: App.shared.coinSettingsManager, walletManager: App.shared.walletManager)
        let presenter = BlockchainSettingsPresenter(router: router, interactor: interactor, coin: coin, settings: settings, updateDelegate: delegate)
        let viewController = BlockchainSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
