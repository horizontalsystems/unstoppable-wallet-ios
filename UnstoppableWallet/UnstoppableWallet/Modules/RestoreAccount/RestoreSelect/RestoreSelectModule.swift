import UIKit
import RxSwift

struct RestoreSelectModule {

    static func viewController(accountType: AccountType) -> UIViewController {
        let (enableCoinService, enableCoinView) = EnableCoinModule.module()

        let enableCoinsService = EnableCoinsService(
                appConfigProvider: App.shared.appConfigProvider,
                erc20Provider: EnableCoinsEip20Provider(networkManager: App.shared.networkManager, mode: .erc20),
                bep20Provider: EnableCoinsEip20Provider(networkManager: App.shared.networkManager, mode: .bep20),
                bep2Provider: EnableCoinsBep2Provider(appConfigProvider: App.shared.appConfigProvider)
        )

        let enableCoinsViewModel = EnableCoinsViewModel(service: enableCoinsService)
        let enableCoinsView = EnableCoinsView(viewModel: enableCoinsViewModel)

        let service = RestoreSelectService(
                accountType: accountType,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                coinManager: App.shared.coinManager,
                enableCoinService: enableCoinService,
                enableCoinsService: enableCoinsService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
                viewModel: viewModel,
                enableCoinView: enableCoinView,
                enableCoinsView: enableCoinsView
        )
    }

}
