import UIKit
import RxSwift
import MarketKit

struct RestoreSelectModule {

    static func viewController(accountType: AccountType, sourceViewController: UIViewController?) -> UIViewController {
        let (enableCoinService, enableCoinView) = EnableCoinModule.module()

        let service = RestoreSelectService(
                accountType: accountType,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                marketKit: App.shared.marketKit,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                enableCoinService: enableCoinService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
                viewModel: viewModel,
                enableCoinView: enableCoinView,
                sourceViewController: sourceViewController
        )
    }

}
