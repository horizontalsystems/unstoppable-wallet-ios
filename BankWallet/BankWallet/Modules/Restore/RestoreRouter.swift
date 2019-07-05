import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestore(type: PredefinedAccountType, delegate: IRestoreDelegate) {
        guard let module = RestoreRouter.module(type: type, delegate: delegate) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module() -> UIViewController {
        let router = RestoreRouter()
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

    static func module(type: PredefinedAccountType, delegate: IRestoreDelegate) -> UIViewController? {
        switch type {
        case .mnemonic: return RestoreWordsRouter.module(delegate: delegate)
        case .eos: return nil
        case .binance: return nil
        }
    }

}
