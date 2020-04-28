import UIKit

class PrivacyRouter {
    weak var viewController: UIViewController?
}

extension PrivacyRouter: IPrivacyRouter {

    func showSortMode(currentSortMode: TransactionDataSortMode, delegate: IPrivacySortModeDelegate) {
        let module = PrivacySortModeRouter.module(currentSortMode: currentSortMode, delegate: delegate)
        viewController?.present(module, animated: true)
    }

}

extension PrivacyRouter {

    static func module() -> UIViewController {
        let router = PrivacyRouter()
        let interactor = PrivacyInteractor(initialSyncSettingsManager: App.shared.initialSyncSettingsManager, transactionDataSortTypeSettingManager: App.shared.transactionDataSortModeSettingManager, ethereumRpcModeSettingsManager: App.shared.ethereumRpcModeSettingsManager)
        let presenter = PrivacyPresenter(interactor: interactor, router: router)
        let viewController = PrivacyViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
