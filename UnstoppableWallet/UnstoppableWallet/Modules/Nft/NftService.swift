import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftService {
    private let account: Account
    private let nftAdapterManager: NftAdapterManager
    private let nftMetadataManager: NftMetadataManager
    private let nftMetadataSyncer: NftMetadataSyncer
    private let balanceHiddenManager: BalanceHiddenManager
    private let balanceConversionManager: BalanceConversionManager
    private let coinPriceService: WalletCoinPriceService
    private let disposeBag = DisposeBag()
    private var adapterDisposeBag = DisposeBag()

    var mode: Mode = .lastSale {
        didSet {
            if mode != oldValue {
                syncItems()
            }
        }
    }

    private var recordMap = [BlockchainType: [NftRecord]]()
    private var metadataMap = [BlockchainType: NftAddressMetadata]()
    private var nftItemMap = [String: NftCollectionItem]()

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

    init(account: Account, nftAdapterManager: NftAdapterManager, nftMetadataManager: NftMetadataManager, nftMetadataSyncer: NftMetadataSyncer, balanceHiddenManager: BalanceHiddenManager, balanceConversionManager: BalanceConversionManager, coinPriceService: WalletCoinPriceService) {
        self.account = account
        self.nftAdapterManager = nftAdapterManager
        self.nftMetadataManager = nftMetadataManager
        self.nftMetadataSyncer = nftMetadataSyncer
        self.balanceHiddenManager = balanceHiddenManager
        self.balanceConversionManager = balanceConversionManager
        self.coinPriceService = coinPriceService

        subscribe(disposeBag, nftAdapterManager.adaptersUpdatedObservable) { [weak self] in self?.handle(adapterMap: $0) }
        subscribe(disposeBag, balanceConversionManager.conversionTokenObservable) { [weak self] _ in self?.syncTotalItem() }

        _handle(adapterMap: nftAdapterManager.adapterMap)
    }

    private func allTokens(items: [Item]) -> Set<Token> {
        var tokens = Set<Token>()

        for item in items {
            for assetItem in item.assetItems {
                if let price = assetItem.price {
                    tokens.insert(price.token)
                }
            }
        }

        return tokens
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            for assetItem in item.assetItems {
                assetItem.priceItem = assetItem.price.flatMap { map[$0.token.coin.uid] }
            }
        }
    }

    private func handle(adapterMap: [NftKey: INftAdapter]) {
        queue.async {
            self._handle(adapterMap: adapterMap)
        }
    }

    private func _handle(adapterMap: [NftKey: INftAdapter]) {
        adapterDisposeBag = DisposeBag()
        recordMap = [:]
        metadataMap = [:]

        for (nftKey, adapter) in adapterMap {
            recordMap[nftKey.blockchainType] = adapter.nftRecords
            metadataMap[nftKey.blockchainType] = nftMetadataManager.addressMetadata(nftKey: nftKey)

            adapter.nftRecordsObservable
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] records in
                        self?.handleUpdated(records: records, blockchainType: nftKey.blockchainType)
                    })
                    .disposed(by: adapterDisposeBag)

        }

        nftMetadataManager.addressMetadataObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] nftKey, addressMetadata in
                    self?.handleUpdated(addressMetadata: addressMetadata, nftKey: nftKey)
                })
                .disposed(by: adapterDisposeBag)

        _syncNftItemMap()
    }

    private func handleUpdated(records: [NftRecord], blockchainType: BlockchainType) {
        queue.async {
            self._handleUpdated(records: records, blockchainType: blockchainType)
        }
    }

    private func _handleUpdated(records: [NftRecord], blockchainType: BlockchainType) {
        recordMap[blockchainType] = records
        _syncNftItemMap()
    }

    private func handleUpdated(addressMetadata: NftAddressMetadata, nftKey: NftKey) {
        queue.async {
            self._handleUpdated(addressMetadata: addressMetadata, nftKey: nftKey)
        }
    }

    private func _handleUpdated(addressMetadata: NftAddressMetadata, nftKey: NftKey) {
        guard account == nftKey.account else {
            return
        }

        metadataMap[nftKey.blockchainType] = addressMetadata
        _syncNftItemMap()
    }

    private func _syncNftItemMap() {
        nftItemMap = [:]

        for (blockchainType, records) in recordMap {
            var assetMetadataMap = [NftUid: NftAssetShortMetadata]()
            var collectionMetadataMap = [String: NftCollectionShortMetadata]()

            if let metadata = metadataMap[blockchainType] {
                for meta in metadata.assets {
                    assetMetadataMap[meta.nftUid] = meta
                }
                for meta in metadata.collections {
                    collectionMetadataMap[meta.providerUid] = meta
                }
            }

            for record in records {
                guard let assetMetadata = assetMetadataMap[record.nftUid], let collectionMetadata = collectionMetadataMap[assetMetadata.providerCollectionUid] else {
//                    print("No meta for: \(record.nftUid.uid)")
                    continue
                }

                let uid = assetMetadata.providerCollectionUid
                let nftItem = NftItem(record: record, assetMetadata: assetMetadata)

                if nftItemMap[uid] == nil {
                    nftItemMap[uid] = NftCollectionItem(metadata: collectionMetadata, nftItems: [nftItem])
                } else {
                    nftItemMap[uid]?.nftItems.append(nftItem)
                }
            }
        }

        _syncItems()

        coinPriceService.set(tokens: allTokens(items: items).union(balanceConversionManager.conversionTokens))
    }

    private func syncItems() {
        queue.async {
            self._syncItems()
        }
    }

    private func _syncItems() {
        let items = nftItemMap.map { providerCollectionUid, nftCollectionItem -> Item in
            let collectionMetadata = nftCollectionItem.metadata

            return Item(
                    uid: providerCollectionUid,
                    providerCollectionUid: collectionMetadata?.providerUid,
                    imageUrl: collectionMetadata?.thumbnailImageUrl,
                    name: collectionMetadata?.name ?? providerCollectionUid,
                    count: nftCollectionItem.nftItems.map {
                                $0.record.balance
                            }
                            .reduce(0, +),
                    assetItems: nftCollectionItem.nftItems.map { nftItem in
                        let record = nftItem.record
                        let metadata = nftItem.assetMetadata

                        var price: NftPrice?

                        switch mode {
                        case .lastSale: price = metadata?.lastSalePrice
                        case .average7d: price = collectionMetadata?.averagePrice7d
                        case .average30d: price = collectionMetadata?.averagePrice30d
                        }

                        return AssetItem(
                                nftUid: record.nftUid,
                                imageUrl: metadata?.previewImageUrl,
                                name: metadata?.name ?? "#\(record.nftUid.tokenId)",
                                count: record.balance,
                                onSale: metadata?.onSale ?? false,
                                price: price
                        )
                    }
            )
        }

        updatePriceItems(items: items, map: coinPriceService.itemMap(tokens: Array(allTokens(items: items))))

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

        var convertedValue: CoinValue?
        var convertedValueExpired = false

        if let conversionToken = balanceConversionManager.conversionToken, let priceItem = coinPriceService.item(token: conversionToken) {
            convertedValue = CoinValue(kind: .token(token: conversionToken), value: total / priceItem.price.value)
            convertedValueExpired = priceItem.expired
        }

        totalItem = TotalItem(
                currencyValue: CurrencyValue(currency: coinPriceService.currency, value: total),
                expired: false,
                convertedValue: convertedValue,
                convertedValueExpired: convertedValueExpired
        )
    }

    func sort(items: [Item]) -> [Item] {
        items.sorted { item, item2 in
            item.name.caseInsensitiveCompare(item2.name) == .orderedAscending
        }
    }

}

extension NftService: IWalletCoinPriceServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            self.updatePriceItems(items: self.items, map: self.coinPriceService.itemMap(tokens: Array(self.allTokens(items: self.items))))
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

extension NftService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var balanceHiddenObservable: Observable<Bool> {
        balanceHiddenManager.balanceHiddenObservable
    }

    var totalItemObservable: Observable<TotalItem?> {
        totalItemRelay.asObservable()
    }

    var balanceHidden: Bool {
        balanceHiddenManager.balanceHidden
    }

    func refreshMetadata() {
        nftMetadataSyncer.forceSync()
    }

    func toggleBalanceHidden() {
        balanceHiddenManager.toggleBalanceHidden()
    }

    func toggleConversionCoin() {
        balanceConversionManager.toggleConversionToken()
    }

}

extension NftService {

    struct NftCollectionItem {
        let metadata: NftCollectionShortMetadata?
        var nftItems: [NftItem]
    }

    struct NftItem {
        let record: NftRecord
        let assetMetadata: NftAssetShortMetadata?
    }

    class Item {
        let uid: String
        let providerCollectionUid: String?
        let imageUrl: String?
        let name: String
        let count: Int
        let assetItems: [AssetItem]

        init(uid: String, providerCollectionUid: String?, imageUrl: String?, name: String, count: Int, assetItems: [AssetItem]) {
            self.uid = uid
            self.providerCollectionUid = providerCollectionUid
            self.imageUrl = imageUrl
            self.name = name
            self.count = count
            self.assetItems = assetItems
        }
    }

    class AssetItem {
        let nftUid: NftUid
        let imageUrl: String?
        let name: String
        let count: Int
        let onSale: Bool
        let price: NftPrice?
        var priceItem: WalletCoinPriceService.Item?

        init(nftUid: NftUid, imageUrl: String?, name: String, count: Int, onSale: Bool, price: NftPrice?) {
            self.nftUid = nftUid
            self.imageUrl = imageUrl
            self.name = name
            self.count = count
            self.onSale = onSale
            self.price = price
        }

    }

    struct TotalItem {
        let currencyValue: CurrencyValue
        let expired: Bool
        let convertedValue: CoinValue?
        let convertedValueExpired: Bool
    }

    enum Mode: CaseIterable {
        case lastSale
        case average7d
        case average30d
    }

}
