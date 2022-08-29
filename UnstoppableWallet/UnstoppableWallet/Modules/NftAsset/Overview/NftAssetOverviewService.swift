import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftAssetOverviewService {
    let providerCollectionUid: String
    let nftUid: NftUid
    private let nftMetadataManager: NftMetadataManager
    private let marketKit: MarketKit.Kit
    private let coinPriceService: WalletCoinPriceService
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-asset-service", qos: .userInitiated)

    init(providerCollectionUid: String, nftUid: NftUid, nftMetadataManager: NftMetadataManager, marketKit: MarketKit.Kit, coinPriceService: WalletCoinPriceService) {
        self.providerCollectionUid = providerCollectionUid
        self.nftUid = nftUid
        self.nftMetadataManager = nftMetadataManager
        self.marketKit = marketKit
        self.coinPriceService = coinPriceService

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        nftMetadataManager.nftAssetMetadataSingle(providerCollectionUid: providerCollectionUid, nftUid: nftUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] metadata in
                    self?.handle(item: Item(metadata: metadata))
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private func handle(item: Item) {
        queue.async {
            let tokens = self._allTokens(item: item)
            self._fillCoinPrices(item: item, tokens: tokens)
            self.coinPriceService.set(tokens: tokens)

            self.state = .completed(item)
        }
    }

    private func _allTokens(item: Item) -> Set<Token> {
        let priceItems = [item.lastSale, item.average7d, item.average30d, item.collectionFloor, item.bestOffer, item.sale?.price]
        return Set(priceItems.compactMap { $0?.nftPrice.token })
    }

    private func _fillCoinPrices(item: Item, tokens: Set<Token>) {
        _fillCoinPrices(item: item, map: coinPriceService.itemMap(tokens: Array(tokens)))
    }

    private func _fillCoinPrices(item: Item, map: [String: WalletCoinPriceService.Item]) {
        _fill(priceItem: item.lastSale, map: map)
        _fill(priceItem: item.average7d, map: map)
        _fill(priceItem: item.average30d, map: map)
        _fill(priceItem: item.collectionFloor, map: map)
        _fill(priceItem: item.bestOffer, map: map)
        _fill(priceItem: item.sale?.price, map: map)
    }

    private func _fill(priceItem: PriceItem?, map: [String: WalletCoinPriceService.Item]) {
        guard let coinUid = priceItem?.nftPrice.token.coin.uid else {
            return
        }

        priceItem?.coinPrice = map[coinUid]
    }

}

extension NftAssetOverviewService: IWalletCoinPriceServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            guard case .completed(let item) = self.state else {
                return
            }

            self._fillCoinPrices(item: item, tokens: self._allTokens(item: item))
            self.state = .completed(item)
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            guard case .completed(let item) = self.state else {
                return
            }

            self._fillCoinPrices(item: item, map: itemsMap)
            self.state = .completed(item)
        }
    }
}

extension NftAssetOverviewService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    func resync() {
        sync()
    }

}

extension NftAssetOverviewService {

    class Item {
        let metadata: NftAssetMetadata

        var lastSale: PriceItem?
        var average7d: PriceItem?
        var average30d: PriceItem?
        var collectionFloor: PriceItem?
        var bestOffer: PriceItem?
        var sale: SaleItem?

        init(metadata: NftAssetMetadata) {
            self.metadata = metadata

            lastSale = metadata.lastSalePrice.map { PriceItem(nftPrice: $0) }
            average7d = metadata.collectionAveragePrice7d.map { PriceItem(nftPrice: $0) }
            average30d = metadata.collectionAveragePrice30d.map { PriceItem(nftPrice: $0) }
            collectionFloor = metadata.collectionFloorPrice.map { PriceItem(nftPrice: $0) }
            bestOffer = metadata.bestOffer.map { PriceItem(nftPrice: $0) }
            sale = metadata.saleInfo.map { saleInfo in
                SaleItem(
                        untilDate: saleInfo.untilDate,
                        type: saleInfo.type,
                        price: saleInfo.price.map { PriceItem(nftPrice: $0) }
                )
            }
        }
    }

    class SaleItem {
        let untilDate: Date
        let type: NftAssetMetadata.SalePriceType
        let price: PriceItem?

        init(untilDate: Date, type: NftAssetMetadata.SalePriceType, price: PriceItem?) {
            self.untilDate = untilDate
            self.type = type
            self.price = price
        }
    }

    class PriceItem {
        let nftPrice: NftPrice
        var coinPrice: WalletCoinPriceService.Item?

        init(nftPrice: NftPrice, coinPrice: WalletCoinPriceService.Item? = nil) {
            self.nftPrice = nftPrice
            self.coinPrice = coinPrice
        }
    }

}
