import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class TransactionsService {
    private static let pageLimit = 20

    private let walletManager: WalletManager
    private let rateService: HistoricalRateService
    private let nftMetadataService: NftMetadataService
    private let poolGroupFactory = PoolGroupFactory()

    private let disposeBag = DisposeBag()
    private var poolGroupDisposeBag = DisposeBag()

    private var poolGroup = PoolGroup(pools: [])

    private let itemDataRelay = PublishRelay<ItemData>()
    private let itemUpdatedRelay = PublishRelay<Item>()
    private(set) var items: [Item] = []

    private let syncingRelay = PublishRelay<Bool>()
    private(set) var syncing = false {
        didSet {
            if oldValue != syncing {
                syncingRelay.accept(syncing)
            }
        }
    }

    private let typeFilterRelay = PublishRelay<TransactionTypeFilter>()
    private(set) var typeFilter: TransactionTypeFilter = .all {
        didSet {
            typeFilterRelay.accept(typeFilter)
        }
    }

    private let blockchainRelay = PublishRelay<Blockchain?>()
    private(set) var blockchain: Blockchain? {
        didSet {
            blockchainRelay.accept(blockchain)
        }
    }

    private let configuredTokenRelay = PublishRelay<ConfiguredToken?>()
    private(set) var configuredToken: ConfiguredToken? {
        didSet {
            configuredTokenRelay.accept(configuredToken)
        }
    }

    private let canResetRelay = PublishRelay<Bool>()

    private(set) var allBlockchains = [Blockchain]()

    private var lastRequestedCount = TransactionsService.pageLimit
    private var loading = false {
        didSet {
            _syncSyncing()
        }
    }
    private var poolGroupSyncing = false {
        didSet {
            _syncSyncing()
        }
    }
    private var loadMoreRequested = false
    private var poolUpdateRequested = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions-service")

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager, rateService: HistoricalRateService, nftMetadataService: NftMetadataService) {
        self.walletManager = walletManager
        self.rateService = rateService
        self.nftMetadataService = nftMetadataService

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in self?.syncWallets() }
        subscribe(disposeBag, rateService.ratesChangedObservable) { [weak self] in self?.handleRatesChanged() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
        subscribe(disposeBag, nftMetadataService.assetsBriefMetadataObservable) { [weak self] in self?.handle(assetsBriefMetadata: $0) }

        _syncWallets()
    }

    private var _canReset: Bool {
        typeFilter != .all || blockchain != nil || configuredToken != nil
    }

    private func syncWallets() {
        queue.async {
            self._syncWallets()
        }
    }

    private func _syncWallets() {
        allBlockchains = Array(Set(walletManager.activeWallets.map { $0.token.blockchain }))

        if let blockchain = blockchain, !allBlockchains.contains(blockchain) {
            self.blockchain = nil
        }

        if let configuredToken = configuredToken, !walletManager.activeWallets.contains(where: { $0.configuredToken == configuredToken }) {
            self.configuredToken = nil
            blockchain = nil
        }

        _syncCanReset()

//        print("SYNC POOL GROUP: sync wallets: \(walletManager.activeWallets.count)")
        _syncPoolGroup()
    }

    private func syncPoolGroup() {
        queue.async {
            self._syncPoolGroup()
        }
    }

    private func _syncPoolGroup() {
        poolGroup = poolGroupFactory.poolGroup(
                wallets: walletManager.activeWallets,
                blockchainType: blockchain?.type,
                filter: typeFilter,
                configuredToken: configuredToken
        )

        _initPoolGroup()
    }

    private func _initPoolGroup() {
        poolGroupDisposeBag = DisposeBag()

        lastRequestedCount = Self.pageLimit
        loading = false
        loadMoreRequested = true
        poolUpdateRequested = false

//        transactions = [] // todo: required???

//        print("LOAD: init pool group")
        _load()

        poolGroupSyncing = poolGroup.syncing

        poolGroup.invalidatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] in
                    self?.onPoolGroupInvalidated()
                })
                .disposed(by: poolGroupDisposeBag)

        poolGroup.itemsUpdatedObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] transactionItems in
                    self?.handleUpdated(transactionItems: transactionItems)
                })
                .disposed(by: poolGroupDisposeBag)

        poolGroup.syncingObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] syncing in
                    self?.handleUpdated(poolGroupSyncing: syncing)
                })
                .disposed(by: poolGroupDisposeBag)
    }

    private func _load() {
        guard !loading else {
            return
        }

        guard loadMoreRequested || poolUpdateRequested else {
            return
        }

        loading = true
        poolUpdateRequested = false

        let loadingMore = loadMoreRequested

        poolGroup.itemsSingle(count: lastRequestedCount)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] transactionItems in
                    self?.handle(transactionItems: transactionItems, loadedMore: loadingMore)
                })
                .disposed(by: poolGroupDisposeBag)

    }

    private func nftMetadata(transactionRecord: TransactionRecord, allMetadata: [NftUid: NftAssetBriefMetadata]) -> [NftUid: NftAssetBriefMetadata] {
        var metadata = [NftUid: NftAssetBriefMetadata]()
        for nftUid in transactionRecord.nftUids {
            if let item = allMetadata[nftUid] {
                metadata[nftUid] = item
            }
        }
        return metadata
    }

    private func handle(transactionItems: [TransactionItem], loadedMore: Bool) {
        queue.async {
//            print("Fetched tx items: \(transactionItems.count): \(transactionItems)")

            let nftUids = transactionItems.map { $0.record }.nftUids
            let nftMetadata = self.nftMetadataService.assetsBriefMetadata(nftUids: nftUids)

            let missingNftUids = nftUids.subtracting(Set(nftMetadata.keys))
            if !missingNftUids.isEmpty {
                self.nftMetadataService.fetch(nftUids: missingNftUids)
            }

            self.items = transactionItems.map { transactionItem in
                Item(
                        transactionItem: transactionItem,
                        nftMetadata: self.nftMetadata(transactionRecord: transactionItem.record, allMetadata: nftMetadata),
                        currencyValue: self.currencyValue(record: transactionItem.record, rate: self.rate(record: transactionItem.record))
                )
            }
            self._reportItemData()

            if loadedMore {
                self.loadMoreRequested = false
            }

            self.loading = false
            self._load()
        }
    }

    private func handleUpdated(transactionItems: [TransactionItem]) {
        queue.async {
//            print("Handle updated tx items: \(transactionItems.count): \(transactionItems)")

            for transactionItem in transactionItems {
                for item in self.items {
                    if item.record == transactionItem.record {
                        item.transactionItem = transactionItem
                        item.currencyValue = self.currencyValue(record: transactionItem.record, rate: self.rate(record: transactionItem.record))
                        self.itemUpdatedRelay.accept(item)
                        break
                    }
                }
            }
        }
    }

    private func handleUpdated(poolGroupSyncing: Bool) {
        queue.async {
            self.poolGroupSyncing = poolGroupSyncing
        }
    }

    private func onPoolGroupInvalidated() {
        queue.async {
            self.poolUpdateRequested = true
//            print("LOAD: pool group invalidated")
            self._load()
        }
    }

    private func handleRatesChanged() {
        queue.async {
            for item in self.items {
                item.currencyValue = self.currencyValue(record: item.record, rate: self.rate(record: item.record))
            }

            self._reportItemData()
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        queue.async {
            for item in self.items {
                if let rateKey = self.rateKey(record: item.record), rateKey == rate.0 {
                    item.currencyValue = self.currencyValue(record: item.record, rate: rate.1)
                    self.itemUpdatedRelay.accept(item)
                }
            }
        }
    }

    private func rateKey(record: TransactionRecord) -> RateKey? {
        guard let token = record.mainValue?.token else {
            return nil
        }

        return RateKey(token: token, date: record.date)
    }

    private func rate(record: TransactionRecord) -> CurrencyValue? {
        guard let rateKey = rateKey(record: record) else {
            return nil
        }

        return rateService.rate(key: rateKey)
    }

    private func currencyValue(record: TransactionRecord, rate: CurrencyValue?) -> CurrencyValue? {
        guard let rate = rate, let decimalValue = record.mainValue?.decimalValue else {
            return nil
        }

        return CurrencyValue(currency: rate.currency, value: decimalValue * rate.value)
    }

    private func _reportItemData() {
        itemDataRelay.accept(itemData)
    }

    private func _syncCanReset() {
        canResetRelay.accept(_canReset)
    }

    private func _syncSyncing() {
        syncing = loading || poolGroupSyncing
    }

    private func handle(assetsBriefMetadata: [NftUid: NftAssetBriefMetadata]) {
        queue.async {
            let fetchedNftUids = Set(assetsBriefMetadata.keys)

            for item in self.items {
                let fetchedItemNftUids = item.transactionItem.record.nftUids.intersection(fetchedNftUids)

                guard !fetchedItemNftUids.isEmpty else {
                    continue
                }

                for nftUid in fetchedItemNftUids {
                    item.nftMetadata[nftUid] = assetsBriefMetadata[nftUid]
                }

                self.itemUpdatedRelay.accept(item)
            }
        }
    }

}

extension TransactionsService {

    var typeFilterObservable: Observable<TransactionTypeFilter> {
        typeFilterRelay.asObservable()
    }

    var blockchainObservable: Observable<Blockchain?> {
        blockchainRelay.asObservable()
    }

    var configuredTokenObservable: Observable<ConfiguredToken?> {
        configuredTokenRelay.asObservable()
    }

    var itemDataObservable: Observable<ItemData> {
        itemDataRelay.asObservable()
    }

    var itemUpdatedObservable: Observable<Item> {
        itemUpdatedRelay.asObservable()
    }

    var syncingObservable: Observable<Bool> {
        syncingRelay.asObservable()
    }

    var canResetObservable: Observable<Bool> {
        canResetRelay.asObservable()
    }

    var itemData: ItemData {
        ItemData(items: items, allLoaded: lastRequestedCount > items.count)
    }

    var canReset: Bool {
        queue.sync {
            _canReset
        }
    }

    func set(typeFilter: TransactionTypeFilter) {
        queue.async {
            guard self.typeFilter != typeFilter else {
                return
            }

            self.typeFilter = typeFilter

            self._syncCanReset()

//            print("SYNC POOL GROUP: set type filter")
            self._syncPoolGroup()
        }
    }

    func set(blockchain: Blockchain?) {
        queue.async {
            guard self.blockchain != blockchain else {
                return
            }

            self.blockchain = blockchain
            self.configuredToken = nil

            self._syncCanReset()

//            print("SYNC POOL GROUP: set blockchain")
            self._syncPoolGroup()
        }
    }

    func set(configuredToken: ConfiguredToken?) {
        queue.async {
            guard self.configuredToken != configuredToken else {
                return
            }

            self.configuredToken = configuredToken
            self.blockchain = configuredToken?.token.blockchain

            self._syncCanReset()

//            print("SYNC POOL GROUP: set token")
            self._syncPoolGroup()
        }
    }

    func reset() {
        queue.async {
            guard self._canReset else {
                return
            }

            self.typeFilter = .all
            self.blockchain = nil
            self.configuredToken = nil

            self._syncCanReset()

//            print("SYNC POOL GROUP: reset")
            self._syncPoolGroup()
        }
    }

    func record(uid: String) -> TransactionRecord? {
        queue.sync {
            items.first(where: { $0.record.uid == uid })?.record
        }
    }

    func fetchRate(index: Int) {
        queue.async {
            guard index < self.items.count else {
                return
            }

            let item = self.items[index]

            guard item.currencyValue == nil, let rateKey = self.rateKey(record: item.record) else {
                return
            }

            self.rateService.fetchRate(key: rateKey)
        }
    }

    func loadMoreIfRequired(index: Int) {
        queue.async {
//            print("load more: \(index) --- \(self.items.count)")

            guard index > self.items.count - 5 else {
                return
            }

            guard !self.loadMoreRequested else {
                return
            }

            guard self.lastRequestedCount == self.items.count else {
                return
            }

            self.lastRequestedCount = self.items.count + Self.pageLimit
            self.loadMoreRequested = true
//            print("LOAD: load more")
            self._load()
        }
    }

}

extension TransactionsService {

    struct ItemData {
        let items: [Item]
        let allLoaded: Bool
    }

    class Item {
        var transactionItem: TransactionItem
        var nftMetadata: [NftUid: NftAssetBriefMetadata]
        var currencyValue: CurrencyValue?

        var record: TransactionRecord {
            transactionItem.record
        }

        init(transactionItem: TransactionItem, nftMetadata: [NftUid: NftAssetBriefMetadata], currencyValue: CurrencyValue?) {
            self.transactionItem = transactionItem
            self.nftMetadata = nftMetadata
            self.currencyValue = currencyValue
        }
    }

}

