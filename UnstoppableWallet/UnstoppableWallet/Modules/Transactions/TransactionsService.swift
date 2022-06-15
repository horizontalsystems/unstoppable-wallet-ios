import Foundation
import RxSwift
import CurrencyKit

class TransactionsService {
    private let evmBlockchainManager: EvmBlockchainManager
    private var disposeBag = DisposeBag()
    private let recordsService: TransactionRecordsService
    private let syncStateService: TransactionSyncStateService
    private let rateService: HistoricalRateService
    private let filterHelper: TransactionFilterHelper

    private let queue = DispatchQueue(label: "transactions_services.items_queue", qos: .userInitiated)

    private var walletFiltersSubject = BehaviorSubject<(wallets: [TransactionWallet], selected: Int?)>(value: (wallets: [], selected: nil))
    private var typeFiltersSubject = BehaviorSubject<(types: [TransactionTypeFilter], selected: Int)>(value: (types: [], selected: 0))
    private var itemsSubject = PublishSubject<[Item]>()
    private var updatedItemSubject = PublishSubject<Item>()

    private var records = [TransactionRecord]()
    private var items = [Item]()
    private var loadingMore = false

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager, evmBlockchainManager: EvmBlockchainManager) {
        self.evmBlockchainManager = evmBlockchainManager

        recordsService = TransactionRecordsService(adapterManager: adapterManager)
        syncStateService = TransactionSyncStateService(adapterManager: adapterManager)
        rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        filterHelper = TransactionFilterHelper()

        subscribe(disposeBag, recordsService.recordsObservable) { [weak self] in self?.handle(records: $0) }
        subscribe(disposeBag, recordsService.updatedRecordObservable) { [weak self] in self?.handle(updatedRecord: $0) }
        subscribe(disposeBag, syncStateService.lastBlockInfoObservable) { [weak self] in self?.handle(source: $0, lastBlockInfo: $1) }
        subscribe(disposeBag, rateService.ratesChangedObservable) { [weak self] in self?.handleRatesChanged() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in self?.handle(updatedWallets: walletManager.activeWallets) }

        if !adapterManager.adapterMap.isEmpty {
            handle(updatedWallets: walletManager.activeWallets)
        }
    }

    private func groupWalletsBySource(transactionWallets: [TransactionWallet]) -> [TransactionWallet] {
        var groupedWallets = [TransactionWallet]()

        for wallet in transactionWallets {
            if evmBlockchainManager.allBlockchains.contains(wallet.source.blockchain) {
                if !groupedWallets.contains(where: { wallet.source == $0.source }) {
                    groupedWallets.append(TransactionWallet(token: nil, source: wallet.source, badge: wallet.badge))
                }
            } else {
                groupedWallets.append(wallet)
            }
        }

        return groupedWallets
    }

    private func handle(updatedWallets: [Wallet]) {
        queue.sync {
            records = []
            items = []
            itemsSubject.onNext(items)
        }

        filterHelper.set(wallets: updatedWallets)

        let wallets = filterHelper.wallets
        let walletsGroupedBySource = groupWalletsBySource(transactionWallets: wallets)

        syncStateService.set(sources: walletsGroupedBySource.map { $0.source })
        recordsService.set(wallets: wallets, walletsGroupedBySource: walletsGroupedBySource, selectedWallet: filterHelper.selectedWallet, typeFilter: filterHelper.selectedType)

        walletFiltersSubject.onNext(filterHelper.walletFilters)
        typeFiltersSubject.onNext(filterHelper.typeFilters)
    }

    private func handle(records: [TransactionRecord]) {
        queue.async {
            let allLoaded = records.count < self.records.count + TransactionsModule.pageLimit

            self.records = records

            let nonSpamRecords = records.filter { !$0.spam }

            if !allLoaded && nonSpamRecords.count < self.items.count + TransactionsModule.pageLimit {
                self.recordsService.load(count: self.records.count + TransactionsModule.pageLimit)
                return
            }

            self.items = nonSpamRecords.map { record in
                self.createItem(from: record)
            }

            self.itemsSubject.onNext(self.items)

            self.loadingMore = false
        }
    }

    private func handleRatesChanged() {
        queue.async {
            for (index, item) in self.items.enumerated() {
                if item.record.mainValue != nil {
                    self.items[index] = self.createItem(from: item.record)
                }
            }

            self.itemsSubject.onNext(self.items)
        }
    }

    private func handle(updatedRecord record: TransactionRecord) {
        queue.async {
            for (index, item) in self.items.enumerated() {
                if item.record.uid == record.uid {
                    self.update(item: item, index: index, record: record)
                }
            }
        }
    }

    private func handle(source: TransactionSource, lastBlockInfo: LastBlockInfo) {
        queue.async {
            for (index, item) in self.items.enumerated() {
                if item.record.source == source && item.record.changedBy(oldBlockInfo: item.lastBlockInfo, newBlockInfo: lastBlockInfo) {
                    self.update(item: item, index: index, lastBlockInfo: lastBlockInfo)
                }
            }
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        queue.async {
            for (index, item) in self.items.enumerated() {
                if let transactionValue = item.record.mainValue, transactionValue.coin == rate.0.coin && item.record.date == rate.0.date {
                    self.update(item: item, index: index, currencyValue: self._currencyValue(transactionValue: transactionValue, rate: rate.1))
                }
            }
        }
    }

    private func update(item: Item, index: Int, record: TransactionRecord? = nil, lastBlockInfo: LastBlockInfo? = nil, currencyValue: CurrencyValue? = nil) {
        let record = record ?? item.record
        let lastBlockInfo = lastBlockInfo ?? item.lastBlockInfo
        let currencyValue = currencyValue ?? item.currencyValue

        let item = Item(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
        items[index] = item
        updatedItemSubject.onNext(item)
    }

    private func createItem(from record: TransactionRecord) -> Item {
        let lastBlockInfo = syncStateService.lastBlockInfo(source: record.source)

        var currencyValue: CurrencyValue? = nil
        if let transactionValue = record.mainValue, case .coinValue(let token, _) = transactionValue {
            currencyValue = _currencyValue(transactionValue: transactionValue, rate: rateService.rate(key: RateKey(coin: token.coin, date: record.date)))
        }

        return Item(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
    }

    private func _currencyValue(transactionValue: TransactionValue, rate: CurrencyValue?) -> CurrencyValue? {
        if let rate = rate, case .coinValue(_, let value) = transactionValue {
            return CurrencyValue(currency: rate.currency, value: value * rate.value)
        }

        return nil
    }

}

extension TransactionsService {

    var allItems: [Item] {
        queue.sync {
            items
        }
    }

    var typeFilters: (types: [TransactionTypeFilter], selected: Int) {
        filterHelper.typeFilters
    }

    var walletFilters: (wallets: [TransactionWallet], selected: Int?) {
        filterHelper.walletFilters
    }

    var walletFiltersObservable: Observable<(wallets: [TransactionWallet], selected: Int?)> {
        walletFiltersSubject.asObservable()
    }

    var typeFiltersObservable: Observable<(types: [TransactionTypeFilter], selected: Int)> {
        typeFiltersSubject.asObservable()
    }

    var itemsObservable: Observable<[Item]> {
        itemsSubject.asObservable()
    }

    var updatedItemObservable: Observable<Item> {
        updatedItemSubject.asObservable()
    }

    var syncing: Bool {
        syncStateService.syncing
    }

    var syncingObservable: Observable<Bool> {
        syncStateService.syncingObservable
    }

    func set(selectedWalletIndex: Int?) {
        filterHelper.set(selectedWalletIndex: selectedWalletIndex)
        recordsService.set(selectedWallet: filterHelper.selectedWallet)
    }

    func set(selectedTypeIndex: Int) {
        filterHelper.set(selectedTypeIndex: selectedTypeIndex)
        recordsService.set(typeFilter: filterHelper.selectedType)
    }

    func loadMore() {
        guard !loadingMore else {
            return
        }

        loadingMore = true

        queue.async {
            self.recordsService.load(count: self.records.count + TransactionsModule.pageLimit)
        }
    }

    func fetchRate(for uid: String) {
        queue.async {
            if let item = self.items.first(where: { $0.record.uid == uid }), item.currencyValue == nil,
               let transactionValue = item.record.mainValue, case .coinValue(let token, _) = transactionValue {
                self.rateService.fetchRate(key: RateKey(coin: token.coin, date: item.record.date))
            }
        }
    }

    func item(uid: String) -> Item? {
        queue.sync {
            items.first(where: { $0.record.uid == uid })
        }
    }

}

extension TransactionsService {

    struct Item {
        let record: TransactionRecord
        var lastBlockInfo: LastBlockInfo?
        var currencyValue: CurrencyValue?
    }

}
