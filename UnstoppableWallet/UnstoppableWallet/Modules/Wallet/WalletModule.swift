import UIKit
import ThemeKit
import RxSwift

struct WalletModule {

    static func viewController() -> UIViewController {
        let adapterService = WalletAdapterService(adapterManager: App.shared.adapterManager)

        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = WalletService(
                adapterService: adapterService,
                coinPriceService: coinPriceService,
                cacheManager: App.shared.enabledWalletCacheManager,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                sortTypeManager: App.shared.sortTypeManager,
                localStorage: App.shared.localStorage,
                rateAppManager: App.shared.rateAppManager,
                feeCoinProvider: App.shared.feeCoinProvider
        )

        adapterService.delegate = service
        coinPriceService.delegate = service

        let viewModel = WalletViewModel(
                service: service,
                factory: WalletViewItemFactory()
        )

        return WalletViewController(viewModel: viewModel)
    }

}
