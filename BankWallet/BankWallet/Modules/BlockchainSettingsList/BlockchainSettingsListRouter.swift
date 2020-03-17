import UIKit

class BlockchainSettingsListRouter {
    weak var viewController: UIViewController?

    private let delegate: IBlockchainSettingsDelegate?

    init(delegate: IBlockchainSettingsDelegate? = nil) {
        self.delegate = delegate
    }

}

extension BlockchainSettingsListRouter: IBlockchainSettingsListRouter {

    func notifyConfirm(settings: [BlockchainSetting]) {
        delegate?.onConfirm(settings: settings)
    }

    func showSettings(coin: Coin, settings: BlockchainSetting, delegate: IBlockchainSettingsUpdateDelegate) {
        viewController?.navigationController?.pushViewController(BlockchainSettingsRouter.module(coin: coin, settings: settings, delegate: delegate), animated: true)
    }

}

extension BlockchainSettingsListRouter {

    static func module(selectedCoins: [Coin], proceedMode: RestoreRouter.ProceedMode, canSave: Bool, delegate: IBlockchainSettingsDelegate? = nil) -> UIViewController {
        let router = BlockchainSettingsListRouter(delegate: delegate)
        let interactor = BlockchainSettingsListInteractor(blockchainSettingsManager: App.shared.coinSettingsManager, walletManager: App.shared.walletManager)
        let presenter = BlockchainSettingsListPresenter(proceedMode: proceedMode, router: router, interactor: interactor, selectedCoins: selectedCoins, canSave: canSave)
        let viewController = BlockchainSettingsListViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
