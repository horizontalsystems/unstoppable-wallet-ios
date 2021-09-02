import UIKit
import ThemeKit
import RxSwift

struct WalletModule {

    static func viewController() -> UIViewController {
        let adapterService = WalletAdapterService(adapterManager: App.shared.adapterManagerNew)

        let rateService = WalletRateService(
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let service = WalletService(
                adapterService: adapterService,
                rateService: rateService,
                cacheManager: App.shared.enabledWalletCacheManager,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManagerNew,
                sortTypeManager: App.shared.sortTypeManager,
                localStorage: App.shared.localStorage,
                rateAppManager: App.shared.rateAppManager,
                feeCoinProvider: App.shared.feeCoinProvider
        )

        adapterService.delegate = service
        rateService.delegate = service

        let viewModel = WalletViewModel(
                service: service,
                rateService: rateService,
                factory: WalletViewItemFactory()
        )

        return WalletViewController(viewModel: viewModel)
    }

}
