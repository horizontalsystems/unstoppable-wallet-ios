import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?
}

extension RestoreRouter: IRestoreRouter {

    func showRestore(type: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate) {
        guard let module = RestoreRouter.module(type: type, mode: .pushed, delegate: delegate) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module(delegate: IRestoreDelegate? = nil) -> UIViewController {
        let router = RestoreRouter()
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator, delegate: delegate)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

    static func module(type: PredefinedAccountType, mode: PresentationMode, delegate: IRestoreAccountTypeDelegate) -> UIViewController? {
        switch type {
        case .mnemonic: return RestoreWordsRouter.module(mode: mode, delegate: delegate)
        case .eos: return nil
        case .binance: return nil
        }
    }

    enum PresentationMode {
        case pushed
        case presented
    }

}
