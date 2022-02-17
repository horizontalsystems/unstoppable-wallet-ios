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

    private let statsItemRelay = PublishRelay<StatsItem>()
    private(set) var statsItem: StatsItem

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-asset-service", qos: .userInitiated)

    init?(collectionUid: String, tokenId: String, nftManager: NftManager, coinPriceService: WalletCoinPriceService) {
        self.nftManager = nftManager
        self.coinPriceService = coinPriceService

        guard let collection = nftManager.collection(uid: collectionUid), let asset = nftManager.asset(collectionUid: collectionUid, tokenId: tokenId) else {
            return nil
        }

        self.collection = collection
        self.asset = asset

        statsItem = StatsItem(
                lastSale: asset.lastSalePrice.map { PriceItem(nftPrice: $0) },
                average7d: collection.averagePrice7d.map { PriceItem(nftPrice: $0) },
                average30d: collection.averagePrice30d.map { PriceItem(nftPrice: $0) }
        )

        _syncCoinPrices()
        syncCollectionStatsAndOrders()
    }

    private func syncCollectionStatsAndOrders() {
        Single.zip(nftManager.collectionStatsSingle(uid: collection.uid), nftManager.assetOrdersSingle(contractAddress: asset.contract.address, tokenId: asset.tokenId))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] stats, orders in
                    self?.handle(stats: stats, orders: orders)
                })
                .disposed(by: disposeBag)
    }

    private func handle(stats: NftCollectionStats, orders: [NftAssetOrder]) {
        queue.async {
            self.handle(stats: stats)
            self.handle(orders: orders)

            self._syncCoinPrices()
            self.handleStatsItemChange()
        }
    }

    private func handle(stats: NftCollectionStats) {
        statsItem.average7d = stats.averagePrice7d.map { PriceItem(nftPrice: $0) }
        statsItem.average30d = stats.averagePrice30d.map { PriceItem(nftPrice: $0) }
        statsItem.collectionFloor = stats.floorPrice.map { PriceItem(nftPrice: $0) }
    }

    private func handle(orders: [NftAssetOrder]) {
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

            statsItem.sale = SaleItem(untilDate: order.closingDate, type: type, price: nftPrice.map { PriceItem(nftPrice: $0) })
        } else {
            let buyNowOrders = orders.filter { $0.side == 1 && $0.v != nil }.sorted { $0.ethValue < $1.ethValue }

            if let order = buyNowOrders.first {
                statsItem.sale = SaleItem(untilDate: order.closingDate, type: .buyNow, price: order.price.map { PriceItem(nftPrice: $0) })
            }
        }

        if !hasTopBid {
            let offerOrders = orders.filter { $0.side == 0 }.sorted { $0.ethValue > $1.ethValue }

            if let order = offerOrders.first {
                statsItem.bestOffer = order.price.map { PriceItem(nftPrice: $0) }
            }
        }
    }

    private func syncCoinPrices() {
        queue.async {
            self._syncCoinPrices()
        }
    }

    private func _syncCoinPrices() {
        let coinUids = allCoinUids()
        fillCoinPrices(coinUids: coinUids)
        coinPriceService.set(coinUids: coinUids)
    }

    private func allCoinUids() -> Set<String> {
        let priceItems = [statsItem.lastSale, statsItem.average7d, statsItem.average30d, statsItem.collectionFloor, statsItem.bestOffer, statsItem.sale?.price]
        return Set(priceItems.compactMap { $0?.nftPrice.platformCoin.coin.uid })
    }

    private func fillCoinPrices(coinUids: Set<String>) {
        fillCoinPrices(map: coinPriceService.itemMap(coinUids: Array(coinUids)))
    }

    private func fillCoinPrices(map: [String: WalletCoinPriceService.Item]) {
        fill(priceItem: statsItem.lastSale, map: map)
        fill(priceItem: statsItem.average7d, map: map)
        fill(priceItem: statsItem.average30d, map: map)
        fill(priceItem: statsItem.collectionFloor, map: map)
        fill(priceItem: statsItem.bestOffer, map: map)
        fill(priceItem: statsItem.sale?.price, map: map)
    }

    private func fill(priceItem: PriceItem?, map: [String: WalletCoinPriceService.Item]) {
        guard let coinUid = priceItem?.nftPrice.platformCoin.coin.uid else {
            return
        }

        priceItem?.coinPrice = map[coinUid]
    }

    private func handleStatsItemChange() {
        statsItemRelay.accept(statsItem)
    }

}

extension NftAssetService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            self.fillCoinPrices(coinUids: self.allCoinUids())
            self.handleStatsItemChange()
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            self.fillCoinPrices(map: itemsMap)
            self.handleStatsItemChange()
        }
    }

}

extension NftAssetService {

    var statsItemObservable: Observable<StatsItem> {
        statsItemRelay.asObservable()
    }

}

extension NftAssetService {

    class StatsItem {
        var lastSale: PriceItem?
        var average7d: PriceItem?
        var average30d: PriceItem?
        var collectionFloor: PriceItem?
        var bestOffer: PriceItem?
        var sale: SaleItem?

        init(lastSale: PriceItem?, average7d: PriceItem?, average30d: PriceItem?) {
            self.lastSale = lastSale
            self.average7d = average7d
            self.average30d = average30d
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
