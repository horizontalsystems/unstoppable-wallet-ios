import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftCollectionsService {
    private let nftManager: NftManager
    private let coinPriceService: WalletCoinPriceService
    private let disposeBag = DisposeBag()

    var mode: Mode = .lastSale {
        didSet {
            if mode != oldValue {
                syncItems()
            }
        }
    }

    private var assetCollection = NftAssetCollection.empty

    private let totalItemRelay = PublishRelay<TotalItem?>()
    private(set) var totalItem: TotalItem? {
        didSet {
            totalItemRelay.accept(totalItem)
        }
    }

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-collections-service", qos: .userInitiated)

    init(nftManager: NftManager, coinPriceService: WalletCoinPriceService) {
        self.nftManager = nftManager
        self.coinPriceService = coinPriceService

        subscribe(disposeBag, nftManager.assetCollectionObservable) { [weak self] in self?.sync(assetCollection: $0) }

        _sync(assetCollection: nftManager.assetCollection())
    }

    private func allCoinUids(items: [Item]) -> Set<String> {
        var uids = Set<String>()

        for item in items {
            for assetItem in item.assetItems {
                if let price = assetItem.price {
                    uids.insert(price.platformCoin.coin.uid)
                }
            }
        }

        return uids
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            for assetItem in item.assetItems {
                assetItem.priceItem = assetItem.price.flatMap { map[$0.platformCoin.coin.uid] }
            }
        }
    }

    private func sync(assetCollection: NftAssetCollection) {
        queue.async {
            self.sync(assetCollection: assetCollection)
        }
    }

    private func _sync(assetCollection: NftAssetCollection) {
        self.assetCollection = assetCollection
        _syncItems()

        coinPriceService.set(coinUids: allCoinUids(items: items))
    }

    private func syncItems() {
        queue.async {
            self._syncItems()
        }
    }

    private func _syncItems() {
        let items = assetCollection.collections.map { collection -> Item in
            let assets = assetCollection.assets.filter { $0.collectionUid == collection.uid }

            return Item(
                    uid: collection.uid,
                    imageUrl: collection.imageUrl,
                    name: collection.name,
                    assetItems: assets.map { asset in
                        var price: NftPrice?

                        switch mode {
                        case .lastSale: price = asset.lastSalePrice
                        case .average7d: price = collection.averagePrice7d
                        case .average30d: price = collection.averagePrice30d
                        }

                        return AssetItem(
                                collectionUid: asset.collectionUid,
                                tokenId: asset.tokenId,
                                imageUrl: asset.imageUrl,
                                name: asset.name,
                                onSale: asset.onSale,
                                price: price
                        )
                    }
            )
        }

        updatePriceItems(items: items, map: coinPriceService.itemMap(coinUids: Array(allCoinUids(items: items))))

        self.items = sort(items: items)
        syncTotalItem()
    }

    private func syncTotalItem() {
        var total: Decimal = 0

        for item in items {
            for assetItem in item.assetItems {
                if let price = assetItem.price, let priceItem = assetItem.priceItem {
                    total += price.value * priceItem.price.value
                }
            }
        }

        totalItem = TotalItem(currencyValue: CurrencyValue(currency: coinPriceService.currency, value: total))
    }

    func sort(items: [Item]) -> [Item] {
        items.sorted { item, item2 in
            item.name.caseInsensitiveCompare(item2.name) == .orderedAscending
        }
    }

}

extension NftCollectionsService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            self.updatePriceItems(items: self.items, map: self.coinPriceService.itemMap(coinUids: Array(self.allCoinUids(items: self.items))))
            self.items = self.sort(items: self.items)
            self.syncTotalItem()
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            self.updatePriceItems(items: self.items, map: itemsMap)
            self.items = self.sort(items: self.items)
            self.syncTotalItem()
        }
    }

}

extension NftCollectionsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var totalItemObservable: Observable<TotalItem?> {
        totalItemRelay.asObservable()
    }

}

extension NftCollectionsService {

    class Item {
        let uid: String
        let imageUrl: String?
        let name: String
        let assetItems: [AssetItem]

        init(uid: String, imageUrl: String?, name: String, assetItems: [AssetItem]) {
            self.uid = uid
            self.imageUrl = imageUrl
            self.name = name
            self.assetItems = assetItems
        }
    }

    class AssetItem {
        let collectionUid: String
        let tokenId: String
        let imageUrl: String?
        let name: String?
        let onSale: Bool
        let price: NftPrice?
        var priceItem: WalletCoinPriceService.Item?

        init(collectionUid: String, tokenId: String, imageUrl: String?, name: String?, onSale: Bool, price: NftPrice?) {
            self.collectionUid = collectionUid
            self.tokenId = tokenId
            self.imageUrl = imageUrl
            self.name = name
            self.onSale = onSale
            self.price = price
        }

    }

    struct TotalItem {
        let currencyValue: CurrencyValue
    }

    enum Mode: CaseIterable {
        case lastSale
        case average7d
        case average30d
    }

}
