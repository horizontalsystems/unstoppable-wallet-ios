import UIKit
import ThemeKit
import MarketKit

class PrivacyRouter {
    weak var viewController: UIViewController?
}

extension PrivacyRouter: IPrivacyRouter {

    func showSortMode(currentSortMode: TransactionDataSortMode, delegate: IPrivacySortModeDelegate) {
        let module = PrivacySortModeRouter.module(currentSortMode: currentSortMode, delegate: delegate)
        viewController?.present(module, animated: true)
    }

    func showSyncMode(platformCoin: PlatformCoin, currentSyncMode: SyncMode, delegate: IPrivacySyncModeDelegate) {
        let module = PrivacySyncModeRouter.module(platformCoin: platformCoin, currentSyncMode: currentSyncMode, delegate: delegate)
        viewController?.present(module, animated: true)
    }

    func showPrivacyInfo() {
        let module = InfoModule.viewController(dataSource: PrivacyInfoDataSource())
        viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
    }

}

extension PrivacyRouter {

    static func module() -> UIViewController {
        let router = PrivacyRouter()
        let interactor = PrivacyInteractor(
                accountManager: App.shared.accountManager,
                initialSyncSettingsManager: App.shared.initialSyncSettingsManager,
                transactionDataSortTypeSettingManager: App.shared.transactionDataSortModeSettingManager
        )
        let presenter = PrivacyPresenter(interactor: interactor, router: router)
        let viewController = PrivacyViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
