import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class NftService {
    private let nftAdapterManager: NftAdapterManager
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
    private var collectionRecordMap = [String: [NftRecord]]()
    private var nftMetadataMap = [NftUid: NftAssetShortMetadata]()
    private var collectionMetadataMap = [String: NftCollectionShortMetadata]()

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

    init(nftAdapterManager: NftAdapterManager, balanceHiddenManager: BalanceHiddenManager, balanceConversionManager: BalanceConversionManager, coinPriceService: WalletCoinPriceService) {
        self.nftAdapterManager = nftAdapterManager
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

    private func handle(adapterMap: [BlockchainType: INftAdapter]) {
        queue.async {
            self._handle(adapterMap: adapterMap)
        }
    }

    private func _handle(adapterMap: [BlockchainType: INftAdapter]) {
        adapterDisposeBag = DisposeBag()
        recordMap = [:]

        for (blockchainType, adapter) in adapterMap {
            recordMap[blockchainType] = adapter.nftRecords

            adapter.nftRecordsObservable
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] records in
                        self?.handleUpdated(records: records, blockchainType: blockchainType)
                    })
                    .disposed(by: disposeBag)
        }

        _syncCollectionRecordMap()
    }

    private func handleUpdated(records: [NftRecord], blockchainType: BlockchainType) {
        queue.async {
            self._handleUpdated(records: records, blockchainType: blockchainType)
        }
    }

    private func _handleUpdated(records: [NftRecord], blockchainType: BlockchainType) {
        recordMap[blockchainType] = records
        _syncCollectionRecordMap()
    }

    private func _syncCollectionRecordMap() {
        collectionRecordMap = [:]

        for records in recordMap.values {
            for record in records {
                let collectionUid = record.collectionUid

                if collectionRecordMap[collectionUid] == nil {
                    collectionRecordMap[collectionUid] = [record]
                } else {
                    collectionRecordMap[collectionUid]?.append(record)
                }
            }
        }

        _syncItems()
    }

    private func syncItems() {
        queue.async {
            self._syncItems()
        }
    }

    private func _syncItems() {
        let items = collectionRecordMap.map { collectionUid, records -> Item in
            let collectionMetadata = collectionMetadataMap[collectionUid]

            return Item(
                    uid: collectionUid,
                    providerCollectionUid: collectionMetadata?.providerUid,
                    imageUrl: collectionMetadata?.thumbnailImageUrl,
                    name: collectionMetadata?.name ?? collectionUid,
                    count: records.map { $0.balance }.reduce(0, +),
                    assetItems: records.map { record in
                        let metadata = nftMetadataMap[record.nftUid]

                        var price: NftPrice?

                        switch mode {
                        case .lastSale: price = metadata?.lastSalePrice
                        case .average7d: price = collectionMetadata?.averagePrice7d
                        case .average30d: price = collectionMetadata?.averagePrice30d
                        }

                        return AssetItem(
                                nftUid: record.nftUid,
                                imageUrl: metadata?.imageUrl,
//                                name: metadata?.name ?? record.displayName,
                                name: record.blockchainType.uid + " - " + (metadata?.name ?? record.displayName),
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

//        coinPriceService.set(tokens: allTokens(items: items).union(balanceConversionManager.conversionTokens))
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

    func toggleBalanceHidden() {
        balanceHiddenManager.toggleBalanceHidden()
    }

    func toggleConversionCoin() {
        balanceConversionManager.toggleConversionToken()
    }

}

extension NftService {

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

enum NftUid: Hashable {
    case evm(blockchainType: BlockchainType, contractAddress: String, tokenId: String)
    case solana(contractAddress: String, tokenId: String)

    var tokenId: String {
        switch self {
        case let .evm(_, _, tokenId): return tokenId
        case let .solana(_, tokenId): return tokenId
        }
    }

    var contractAddress: String {
        switch self {
        case let .evm(_, contractAddress, _): return contractAddress
        case let .solana(contractAddress, _): return contractAddress
        }
    }

    var uid: String {
        switch self {
        case let .evm(blockchainType, contractAddress, tokenId): return "evm-\(blockchainType)-\(contractAddress)-\(tokenId)"
        case let .solana(contractAddress, tokenId): return "solana-\(contractAddress)-\(tokenId)"
        }
    }

    var blockchainType: BlockchainType {
        switch self {
        case let .evm(blockchainType, _, _): return blockchainType
        case .solana: return .unsupported(uid: "solana") // todo
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

    static func ==(lhs: NftUid, rhs: NftUid) -> Bool {
        switch (lhs, rhs) {
        case let (.evm(lhsBlockchainType, lhsContractAddress, lhsTokenId), .evm(rhsBlockchainType, rhsContractAddress, rhsTokenId)): return lhsBlockchainType == rhsBlockchainType && lhsContractAddress == rhsContractAddress && lhsTokenId == rhsTokenId
        case let (.solana(lhsContractAddress, lhsTokenId), .solana(rhsContractAddress, rhsTokenId)): return lhsContractAddress == rhsContractAddress && lhsTokenId == rhsTokenId
        default: return false
        }
    }

}
