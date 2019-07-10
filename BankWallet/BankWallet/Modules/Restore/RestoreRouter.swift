import UIKit

class RestoreRouter {
    weak var viewController: UIViewController?

    private let delegate: IRestoreDelegate

    init(delegate: IRestoreDelegate) {
        self.delegate = delegate
    }

}

extension RestoreRouter: IRestoreRouter {

    func showRestore(predefinedAccountType: IPredefinedAccountType, delegate: IRestoreAccountTypeDelegate) {
        guard let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .pushed, delegate: delegate) else {
            return
        }

        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func notifyRestored(account: Account) {
        delegate.didRestore(account: account)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreRouter {

    static func module(delegate: IRestoreDelegate) -> UIViewController {
        let router = RestoreRouter(delegate: delegate)
        let presenter = RestorePresenter(router: router, accountCreator: App.shared.accountCreator, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let viewController = RestoreViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return WalletNavigationController(rootViewController: viewController)
    }

    static func module(predefinedAccountType: IPredefinedAccountType, mode: PresentationMode, delegate: IRestoreAccountTypeDelegate) -> UIViewController? {
        switch predefinedAccountType {
        case is Words12AccountType: return RestoreWordsRouter.module(mode: mode, delegate: delegate)
        default: return nil
        }
    }

    enum PresentationMode {
        case pushed
        case presented
    }

}
