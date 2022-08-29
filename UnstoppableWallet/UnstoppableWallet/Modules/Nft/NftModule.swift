import UIKit
import ThemeKit

struct NftModule {

    static func viewController() -> UIViewController {
        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = NftService(
                nftAdapterManager: App.shared.nftAdapterManager,
                balanceHiddenManager: App.shared.balanceHiddenManager,
                balanceConversionManager: App.shared.balanceConversionManager,
                coinPriceService: coinPriceService
        )

        coinPriceService.delegate = service

        let viewModel = NftViewModel(service: service)
        let headerViewModel = NftHeaderViewModel(service: service)

        return NftViewController(viewModel: viewModel, headerViewModel: headerViewModel)
    }

}
