import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftAssetOverviewService {
    let providerCollectionUid: String
    let nftUid: NftUid
    let nftKey: NftKey?
    private let nftAdapterManager: NftAdapterManager
    private let nftMetadataManager: NftMetadataManager
    private let marketKit: MarketKit.Kit
    private let coinPriceService: WalletCoinPriceService
    private let nftAdapterDisposeBag = DisposeBag()
    private var nftRecordDisposeBag = DisposeBag()
    private var disposeBag = DisposeBag()

    private var evmNftRecord: EvmNftRecord? = nil {
        didSet {
            syncSendState(evmNftRecord: evmNftRecord)
        }
    }
    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-asset-service", qos: .userInitiated)

    init(providerCollectionUid: String, nftUid: NftUid, nftKey: NftKey?, nftAdapterManager: NftAdapterManager, nftMetadataManager: NftMetadataManager, marketKit: MarketKit.Kit, coinPriceService: WalletCoinPriceService) {
        self.providerCollectionUid = providerCollectionUid
        self.nftUid = nftUid
        self.nftKey = nftKey
        self.nftAdapterManager = nftAdapterManager
        self.nftMetadataManager = nftMetadataManager
        self.marketKit = marketKit
        self.coinPriceService = coinPriceService

        syncNftAdapter(map: nftAdapterManager.adapterMap)
        subscribe(nftAdapterDisposeBag, nftAdapterManager.adaptersUpdatedObservable) { [weak self] in self?.syncNftAdapter(map: $0) }
        sync()
    }

    private func syncNftAdapter(map: [NftKey: INftAdapter]) {
        guard let nftKey = nftKey,
              let adapter = map[nftKey] else {
            return
        }

        nftRecordDisposeBag = DisposeBag()
        subscribe(nftRecordDisposeBag, adapter.nftRecordsObservable) { [weak self] in self?.syncNft(records: $0) }
        syncNft(records: adapter.nftRecords)
    }

    private func syncNft(records: [NftRecord]) {
        evmNftRecord = records.compactMap { $0 as? EvmNftRecord }.first(where: { $0.nftUid == nftUid })
    }

    private func syncSendState(evmNftRecord: EvmNftRecord?) {
        queue.async {
            guard case let .completed(item) = self.state, item.evmNftRecord != evmNftRecord else {
                return
            }

            item.evmNftRecord = evmNftRecord
            self.state = .completed(item)
        }
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        nftMetadataManager.extendedAssetMetadataSingle(nftUid: nftUid, providerCollectionUid: providerCollectionUid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] asset, collection in
                    self?.handle(item: Item(asset: asset, collection: collection, evmNftRecord: self?.evmNftRecord))
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
        var priceItems = [item.lastSale, item.average7d, item.average30d, item.collectionFloor] + item.offers

        if let saleItem = item.sale {
            priceItems.append(contentsOf: saleItem.listings.map { $0.price })
        }

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

        item.offers.forEach {
            _fill(priceItem: $0, map: map)
        }

        if let saleItem = item.sale {
            for listing in saleItem.listings {
                _fill(priceItem: listing.price, map: map)
            }
        }
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

    var providerTitle: String? {
        nftMetadataManager.providerTitle(blockchainType: nftUid.blockchainType)
    }

    func resync() {
        queue.async {
            self.sync()
        }
    }

}

extension NftAssetOverviewService {

    class Item {
        let asset: NftAssetMetadata
        let collection: NftCollectionMetadata

        var lastSale: PriceItem?
        var average7d: PriceItem?
        var average30d: PriceItem?
        var collectionFloor: PriceItem?
        var offers: [PriceItem]
        var sale: SaleItem?
        var evmNftRecord: EvmNftRecord?

        init(asset: NftAssetMetadata, collection: NftCollectionMetadata, evmNftRecord: EvmNftRecord?) {
            self.asset = asset
            self.collection = collection

            lastSale = asset.lastSalePrice.map { PriceItem(nftPrice: $0) }
            average7d = collection.averagePrice7d.map { PriceItem(nftPrice: $0) }
            average30d = collection.averagePrice30d.map { PriceItem(nftPrice: $0) }
            collectionFloor = collection.floorPrice.map { PriceItem(nftPrice: $0) }
            offers = asset.offers.map { PriceItem(nftPrice: $0) }
            sale = asset.saleInfo.map { saleInfo in
                SaleItem(
                        type: saleInfo.type,
                        listings: saleInfo.listings.map { listing in
                            SaleListingItem(
                                    untilDate: listing.untilDate,
                                    price: PriceItem(nftPrice: listing.price)
                            )
                        }
                )
            }
            self.evmNftRecord = evmNftRecord
        }

        var bestOffer: PriceItem? {
            guard !offers.isEmpty else {
                return nil
            }

            guard offers.allSatisfy({ $0.coinPrice != nil }) else {
                return nil
            }

            let sortedOffers = offers.sorted { lhsItem, rhsItem in
                let lhsCurrencyValue = (lhsItem.coinPrice?.price.value ?? 0) * lhsItem.nftPrice.value
                let rhsCurrencyValue = (rhsItem.coinPrice?.price.value ?? 0) * rhsItem.nftPrice.value

                return lhsCurrencyValue > rhsCurrencyValue
            }

            return sortedOffers.first
        }
    }

    class SaleItem {
        let type: NftAssetMetadata.SaleType
        let listings: [SaleListingItem]

        init(type: NftAssetMetadata.SaleType, listings: [SaleListingItem]) {
            self.type = type
            self.listings = listings
        }

        var bestListing: SaleListingItem? {
            guard !listings.isEmpty else {
                return nil
            }

            guard listings.allSatisfy({ $0.price.coinPrice != nil }) else {
                return nil
            }

            let sortedListings = listings.sorted { lhsListing, rhsListing in
                let lhsItem = lhsListing.price
                let rhsItem = rhsListing.price

                let lhsCurrencyValue = (lhsItem.coinPrice?.price.value ?? 0) * lhsItem.nftPrice.value
                let rhsCurrencyValue = (rhsItem.coinPrice?.price.value ?? 0) * rhsItem.nftPrice.value

                return lhsCurrencyValue < rhsCurrencyValue
            }

            return sortedListings.first
        }
    }

    class SaleListingItem {
        let untilDate: Date
        let price: PriceItem

        init(untilDate: Date, price: PriceItem) {
            self.untilDate = untilDate
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

extension EvmNftRecord: Equatable {

    public static func ==(lhs: EvmNftRecord, rhs: EvmNftRecord) -> Bool {
        lhs.nftUid == rhs.nftUid && lhs.blockchainType == rhs.blockchainType
    }

}
