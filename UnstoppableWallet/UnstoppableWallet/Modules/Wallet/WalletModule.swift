import UIKit
import ThemeKit
import RxSwift

struct WalletModule {

    static func viewController() -> UIViewController {
        let rateService = WalletRateService(
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let service = WalletService(
                rateService: rateService,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                sortTypeManager: App.shared.sortTypeManager,
                localStorage: App.shared.localStorage,
                rateAppManager: App.shared.rateAppManager,
                feeCoinProvider: App.shared.feeCoinProvider
        )

        rateService.delegate = service

        let viewModel = WalletViewModel(
                service: service,
                rateService: rateService,
                factory: WalletViewItemFactory()
        )

        return WalletViewController(viewModel: viewModel)
    }

}
