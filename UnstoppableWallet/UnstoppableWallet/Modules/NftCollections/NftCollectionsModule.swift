import UIKit
import ThemeKit

struct NftCollectionsModule {

    static func viewController() -> UIViewController {
        let coinPriceService = WalletCoinPriceService(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let service = NftCollectionsService(nftManager: App.shared.nftManager, coinPriceService: coinPriceService)

        coinPriceService.delegate = service

        let viewModel = NftCollectionsViewModel(service: service)
        let headerViewModel = NftCollectionsHeaderViewModel(service: service)

        return NftCollectionsViewController(viewModel: viewModel, headerViewModel: headerViewModel)
    }

}
