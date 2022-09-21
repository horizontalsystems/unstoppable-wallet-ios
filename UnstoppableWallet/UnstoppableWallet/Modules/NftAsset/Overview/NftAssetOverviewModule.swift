import UIKit

struct NftAssetOverviewModule {

    static func viewController(providerCollectionUid: String, nftUid: NftUid, imageRatio: CGFloat) -> NftAssetOverviewViewController {
        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let account = App.shared.accountManager.activeAccount.flatMap { !$0.watchAccount ? $0 : nil }
        let nftKey = account.map { NftKey(account: $0, blockchainType: .ethereum) } //can send only ethereum nfts

        let service = NftAssetOverviewService(
                providerCollectionUid: providerCollectionUid,
                nftUid: nftUid,
                nftKey: nftKey,
                nftAdapterManager: App.shared.nftAdapterManager,
                nftMetadataManager: App.shared.nftMetadataManager,
                marketKit: App.shared.marketKit,
                coinPriceService: coinPriceService
        )

        coinPriceService.delegate = service

        let viewModel = NftAssetOverviewViewModel(service: service)
        return NftAssetOverviewViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true), imageRatio: imageRatio)
    }

}
