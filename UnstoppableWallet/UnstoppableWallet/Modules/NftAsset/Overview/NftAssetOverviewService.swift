import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftAssetOverviewService {
    private let collectionUid: String
    private let contractAddress: String
    private let tokenId: String
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

    init(collectionUid: String, contractAddress: String, tokenId: String, marketKit: MarketKit.Kit, coinPriceService: WalletCoinPriceService) {
        self.collectionUid = collectionUid
        self.contractAddress = contractAddress
        self.tokenId = tokenId
        self.marketKit = marketKit
        self.coinPriceService = coinPriceService

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        Single.zip(marketKit.nftCollectionSingle(uid: collectionUid), marketKit.nftAssetSingle(contractAddress: contractAddress, tokenId: tokenId))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collection, asset in
                    self?.handle(item: Item(collection: collection, asset: asset))
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private func handle(item: Item) {
        queue.async {
            let coinUids = self._allCoinUids(item: item)
            self._fillCoinPrices(item: item, coinUids: coinUids)
            self.coinPriceService.set(coinUids: coinUids)

            self.state = .completed(item)
        }
    }

    private func _allCoinUids(item: Item) -> Set<String> {
        let priceItems = [item.lastSale, item.average7d, item.average30d, item.collectionFloor, item.bestOffer, item.sale?.price]
        return Set(priceItems.compactMap { $0?.nftPrice.token.coin.uid })
    }

    private func _fillCoinPrices(item: Item, coinUids: Set<String>) {
        _fillCoinPrices(item: item, map: coinPriceService.itemMap(coinUids: Array(coinUids)))
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

            self._fillCoinPrices(item: item, coinUids: self._allCoinUids(item: item))
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
        let collection: NftCollection
        let asset: NftAsset

        var lastSale: PriceItem?
        var average7d: PriceItem?
        var average30d: PriceItem?
        var collectionFloor: PriceItem?
        var bestOffer: PriceItem?
        var sale: SaleItem?

        init(collection: NftCollection, asset: NftAsset) {
            self.collection = collection
            self.asset = asset

            lastSale = asset.lastSalePrice.map { PriceItem(nftPrice: $0) }
            average7d = collection.stats.averagePrice7d.map { PriceItem(nftPrice: $0) }
            average30d = collection.stats.averagePrice30d.map { PriceItem(nftPrice: $0) }
            collectionFloor = collection.stats.floorPrice.map { PriceItem(nftPrice: $0) }

            let orders = asset.orders
            var hasTopBid = false
            let auctionOrders = orders.filter { $0.side == 1 && $0.v == nil }.sorted { $0.ethValue < $1.ethValue }

            if let order = auctionOrders.first {
                let bidOrders = orders.filter { $0.side == 0 && !$0.emptyTaker }.sorted { $0.ethValue > $1.ethValue }

                let type: SalePriceType
                var nftPrice: NftPrice?

                if let bidOrder = bidOrders.first {
                    type = .topBid
                    nftPrice = bidOrder.price
                    hasTopBid = true
                } else {
                    type = .minimumBid
                    nftPrice = order.price
                }

                sale = SaleItem(untilDate: order.closingDate, type: type, price: nftPrice.map { PriceItem(nftPrice: $0) })
            } else {
                let buyNowOrders = orders.filter { $0.side == 1 && $0.v != nil }.sorted { $0.ethValue < $1.ethValue }

                if let order = buyNowOrders.first {
                    sale = SaleItem(untilDate: order.closingDate, type: .buyNow, price: order.price.map { PriceItem(nftPrice: $0) })
                }
            }

            if !hasTopBid {
                let offerOrders = orders.filter { $0.side == 0 }.sorted { $0.ethValue > $1.ethValue }

                if let order = offerOrders.first {
                    bestOffer = order.price.map { PriceItem(nftPrice: $0) }
                }
            }
        }
    }

    class SaleItem {
        let untilDate: Date
        let type: SalePriceType
        let price: PriceItem?

        init(untilDate: Date, type: SalePriceType, price: PriceItem?) {
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

    enum SalePriceType {
        case buyNow
        case topBid
        case minimumBid
    }
}
