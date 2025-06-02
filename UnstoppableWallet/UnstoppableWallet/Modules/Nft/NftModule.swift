import UIKit

enum NftModule {
    static func viewController() -> UIViewController? {
        let coinPriceService = WalletCoinPriceService(
            currencyManager: App.shared.currencyManager,
            priceChangeModeManager: App.shared.priceChangeModeManager,
            marketKit: App.shared.marketKit
        )

        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let service = NftService(
            account: account,
            nftAdapterManager: App.shared.nftAdapterManager,
            nftMetadataManager: App.shared.nftMetadataManager,
            nftMetadataSyncer: App.shared.nftMetadataSyncer,
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
