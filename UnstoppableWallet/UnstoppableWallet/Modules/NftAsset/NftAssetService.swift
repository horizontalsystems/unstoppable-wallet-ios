import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftAssetService {
    private let nftManager: NftManager
    private let coinPriceService: WalletCoinPriceService
    private let disposeBag = DisposeBag()

    let collection: NftCollection
    let asset: NftAsset

    init?(collectionSlug: String, tokenId: String, nftManager: NftManager, coinPriceService: WalletCoinPriceService) {
        self.nftManager = nftManager
        self.coinPriceService = coinPriceService

        guard let collection = nftManager.collection(slug: collectionSlug), let asset = nftManager.asset(collectionSlug: collectionSlug, tokenId: tokenId) else {
            return nil
        }

        self.collection = collection
        self.asset = asset
    }

}

extension NftAssetService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
    }

}

extension NftAssetService {

}

extension NftAssetService {

}
