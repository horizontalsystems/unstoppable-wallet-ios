import UIKit
import ThemeKit

class BlockchainSettingsRouter {
    weak var viewController: UIViewController?

    private let delegate: IBlockchainSettingsDelegate?

    init(delegate: IBlockchainSettingsDelegate? = nil) {
        self.delegate = delegate
    }

}

extension BlockchainSettingsRouter: IBlockchainSettingsRouter {

    func notifyConfirm() {
        delegate?.onConfirm()
    }

    func open(url: String) {
        guard let url = URL(string: url) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}

extension BlockchainSettingsRouter {

    static func module(proceedMode: RestoreRouter.ProceedMode, delegate: IBlockchainSettingsDelegate? = nil) -> UIViewController {
        let router = BlockchainSettingsRouter(delegate: delegate)
        let interactor = BlockchainSettingsInteractor(coinSettingsManager: App.shared.coinSettingsManager)
        let presenter = BlockchainSettingsPresenter(proceedMode: proceedMode, router: router, interactor: interactor)
        let viewController = BlockchainSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
