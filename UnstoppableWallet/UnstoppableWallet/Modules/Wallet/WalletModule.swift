import UIKit
import ThemeKit
import RxSwift

struct WalletModule {

    static func viewController() -> UIViewController {
        let scheduler = SerialDispatchQueueScheduler(qos: .utility, internalSerialQueueName: "io.horizontalsystems.unstoppable.wallet_module")

        let adapterService = WalletAdapterService(
                adapterManager: App.shared.adapterManager,
                scheduler: scheduler
        )

        let rateService = WalletRateService(
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager,
                scheduler: scheduler
        )

        let service = WalletService(
                adapterService: adapterService,
                rateService: rateService,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                sortTypeManager: App.shared.sortTypeManager,
                localStorage: App.shared.localStorage,
                rateAppManager: App.shared.rateAppManager,
                feeCoinProvider: App.shared.feeCoinProvider,
                scheduler: scheduler
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
