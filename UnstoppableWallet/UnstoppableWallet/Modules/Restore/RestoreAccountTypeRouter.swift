import UIKit

class RestoreAccountTypeRouter {
    weak var viewController: UIViewController?

    private let initialRestore: Bool
    private let predefinedAccountType: PredefinedAccountType

    init(predefinedAccountType: PredefinedAccountType, initialRestore: Bool) {
        self.predefinedAccountType = predefinedAccountType
        self.initialRestore = initialRestore
    }

}

extension RestoreAccountTypeRouter: IRestoreAccountTypeRouter {

    func showSelectCoins(accountType: AccountType) {
        let controller = RestoreCoinsRouter.module(predefinedAccountType: predefinedAccountType, accountType: accountType, initialRestore: initialRestore)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }

    func showScanQr(delegate: IScanQrModuleDelegate) {
        let controller = ScanQrRouter.module(delegate: delegate)
        viewController?.present(controller, animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}
