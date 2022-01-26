import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftCollectionsService {
    private let nftManager: NftManager
    private let coinPriceService: WalletCoinPriceService
    private let disposeBag = DisposeBag()

    var mode: Mode = .lastPrice {
        didSet {
            if mode != oldValue {
                syncItems()
            }
        }
    }

    private var collections = [NftCollection]()

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

        subscribe(disposeBag, nftManager.collectionsObservable) { [weak self] in self?.sync(collections: $0) }

        _sync(collections: nftManager.collections())
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

    private func sync(collections: [NftCollection]) {
        queue.async {
            self.sync(collections: collections)
        }
    }

    private func _sync(collections: [NftCollection]) {
        self.collections = collections
        _syncItems()

        coinPriceService.set(coinUids: allCoinUids(items: items))
    }

    private func syncItems() {
        queue.async {
            self._syncItems()
        }
    }

    private func _syncItems() {
        let items = collections.map { collection in
            Item(
                    uid: collection.slug,
                    imageUrl: collection.imageUrl,
                    name: collection.name,
                    assetItems: collection.assets.map { asset in
                        var price: NftPrice?

                        switch mode {
                        case .lastPrice: price = asset.lastPrice
                        case .floorPrice: price = collection.floorPrice
                        }

                        return AssetItem(
                                uid: "\(collection.slug)-\(asset.tokenId)",
                                tokenId: asset.tokenId,
                                imageUrl: asset.imageUrl,
                                name: asset.name,
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
        let uid: String
        let tokenId: Decimal
        let imageUrl: String?
        let name: String?
        let price: NftPrice?
        var priceItem: WalletCoinPriceService.Item?

        init(uid: String, tokenId: Decimal, imageUrl: String?, name: String?, price: NftPrice?) {
            self.uid = uid
            self.tokenId = tokenId
            self.imageUrl = imageUrl
            self.name = name
            self.price = price
        }

    }

    struct TotalItem {
        let currencyValue: CurrencyValue
    }

    enum Mode: CaseIterable {
        case lastPrice
        case floorPrice
    }

}
