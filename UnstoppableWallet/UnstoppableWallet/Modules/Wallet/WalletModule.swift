import UIKit
import ThemeKit
import RxSwift
import StorageKit

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
                marketKit: App.shared.marketKit,
                localStorage: StorageKit.LocalStorage.default,
                rateAppManager: App.shared.rateAppManager,
                balancePrimaryValueManager: App.shared.balancePrimaryValueManager,
                balanceHiddenManager: App.shared.balanceHiddenManager,
                balanceConversionManager: App.shared.balanceConversionManager,
                appManager: App.shared.appManager,
                feeCoinProvider: App.shared.feeCoinProvider,
                reachabilityManager: App.shared.reachabilityManager
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

extension WalletModule {

    enum SortType: String, CaseIterable {
        case balance
        case name
        case percentGrowth

        var title: String {
            switch self {
            case .balance: return "balance.sort.valueHighToLow".localized
            case .name: return "balance.sort.az".localized
            case .percentGrowth: return "balance.sort.price_change".localized
            }
        }

    }

}
