import UIKit
import ThemeKit

struct ManageWalletsModule {

    static func viewController() -> UIViewController? {
        let (enableCoinService, enableCoinView) = EnableCoinModule.module()

        guard let service = ManageWalletsService(
                coinManager: App.shared.coinManagerNew,
                walletManager: App.shared.walletManagerNew,
                accountManager: App.shared.accountManager,
                enableCoinService: enableCoinService
        ) else {
            return nil
        }

        let viewModel = ManageWalletsViewModel(service: service)

        let viewController = ManageWalletsViewController(
                viewModel: viewModel,
                enableCoinView: enableCoinView
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
