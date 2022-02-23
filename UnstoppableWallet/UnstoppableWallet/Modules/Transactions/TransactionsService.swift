import Foundation
import RxSwift
import CurrencyKit

class TransactionsService {
    private var disposeBag = DisposeBag()
    private let recordsService: TransactionRecordsService
    private let syncStateService: TransactionSyncStateService
    private let rateService: HistoricalRateService
    private let filterHelper: TransactionFilterHelper
    private let queue = DispatchQueue(label: "transactions_services.items_queue", qos: .background)

    private var walletFiltersSubject = BehaviorSubject<(wallets: [TransactionWallet], selected: Int?)>(value: (wallets: [], selected: nil))
    private var typeFiltersSubject = BehaviorSubject<(types: [TransactionTypeFilter], selected: Int)>(value: (types: [], selected: 0))
    private var itemsSubject = PublishSubject<[TransactionItem]>()
    private var updatedItemSubject = PublishSubject<TransactionItem>()
    private var syncStateSubject = PublishSubject<AdapterState?>()

    private var items = [TransactionItem]()

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager) {
        recordsService = TransactionRecordsService(adapterManager: adapterManager)
        syncStateService = TransactionSyncStateService(adapterManager: adapterManager)
        rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        filterHelper = TransactionFilterHelper()

        recordsService.recordsObservable
                .subscribe(onNext: { [weak self] records in self?.queue.async { self?.handle(records: records) }})
                .disposed(by: disposeBag)

        recordsService.updatedRecordObservable
                .subscribe(onNext: { [weak self] record in self?.queue.async { self?.handle(updatedRecord: record) }})
                .disposed(by: disposeBag)

        syncStateService.lastBlockInfoObservable
                .subscribe(onNext: { [weak self] (source, lastBlockInfo) in self?.queue.async { self?.handle(source: source, lastBlockInfo: lastBlockInfo) }})
                .disposed(by: disposeBag)

        syncStateService.syncStateObservable
                .subscribe(onNext: { [weak self] syncState in self?.syncStateSubject.onNext(syncState) })
                .disposed(by: disposeBag)

        rateService.ratesChangedObservable
                .subscribe(onNext: { [weak self] in self?.queue.async { self?.handleRatesChanged() }})
                .disposed(by: disposeBag)

        rateService.rateUpdatedObservable
                .subscribe(onNext: { [weak self] rate in self?.queue.async { self?.handle(rate: rate) }})
                .disposed(by: disposeBag)

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] wallets in self?.handle(updatedWallets: walletManager.activeWallets) }
        handle(updatedWallets: walletManager.activeWallets)
    }

    private func groupWalletsBySource(transactionWallets: [TransactionWallet]) -> [TransactionWallet] {
        var groupedWallets = [TransactionWallet]()

        for wallet in transactionWallets {
            switch wallet.source.blockchain {
            case .bitcoin, .bitcoinCash, .litecoin, .dash, .zcash, .bep2: groupedWallets.append(wallet)
            case .evm:
                if !groupedWallets.contains(where: { wallet.source == $0.source }) {
                    groupedWallets.append(TransactionWallet(coin: nil, source: wallet.source, badge: wallet.badge))
                }
            }
        }

        return groupedWallets
    }

    private func handle(updatedWallets: [Wallet]) {
        filterHelper.set(wallets: updatedWallets)

        let wallets = filterHelper.wallets
        let walletsGroupedBySource = groupWalletsBySource(transactionWallets: wallets)

        syncStateService.set(sources: walletsGroupedBySource.map { $0.source })
        recordsService.set(wallets: wallets, walletsGroupedBySource: walletsGroupedBySource)
        recordsService.set(selectedWallet: filterHelper.selectedWallet)
        recordsService.set(typeFilter: filterHelper.selectedType)

        walletFiltersSubject.onNext(filterHelper.walletFilters)
        typeFiltersSubject.onNext(filterHelper.typeFilters)
    }

    private func handle(records: [TransactionRecord]) {
        items = records.map { record in
            createItem(from: record)
        }

        itemsSubject.onNext(items)
    }

    private func handleRatesChanged() {
        for (index, item) in items.enumerated() {
            if item.record.mainValue != nil {
                items[index] = createItem(from: item.record)
            }
        }

        itemsSubject.onNext(items)
    }

    private func handle(updatedRecord record: TransactionRecord) {
        for (index, item) in items.enumerated() {
            if item.record.uid == record.uid {
                update(item: item, index: index, record: record)
            }
        }
    }

    private func handle(source: TransactionSource, lastBlockInfo: LastBlockInfo) {
        for (index, item) in items.enumerated() {
            if item.record.source == source && item.record.changedBy(oldBlockInfo: item.lastBlockInfo, newBlockInfo: lastBlockInfo) {
                update(item: item, index: index, lastBlockInfo: lastBlockInfo)
            }
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        for (index, item) in items.enumerated() {
            if let transactionValue = item.record.mainValue, transactionValue.coin == rate.0.coin && item.record.date == rate.0.date {
                update(item: item, index: index, currencyValue: _currencyValue(transactionValue: transactionValue, rate: rate.1))
            }
        }
    }

    private func update(item: TransactionItem, index: Int, record: TransactionRecord? = nil, lastBlockInfo: LastBlockInfo? = nil, currencyValue: CurrencyValue? = nil) {
        let record = record ?? item.record
        let lastBlockInfo = lastBlockInfo ?? item.lastBlockInfo
        let currencyValue = currencyValue ?? item.currencyValue

        let item = TransactionItem(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
        items[index] = item
        updatedItemSubject.onNext(item)
    }

    private func createItem(from record: TransactionRecord) -> TransactionItem {
        let lastBlockInfo = syncStateService.lastBlockInfo(source: record.source)

        var currencyValue: CurrencyValue? = nil
        if let transactionValue = record.mainValue, case .coinValue(let platformCoin, _) = transactionValue {
            currencyValue = _currencyValue(transactionValue: transactionValue, rate: rateService.rate(key: RateKey(coin: platformCoin.coin, date: record.date)))
        }

        return TransactionItem(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
    }

    private func _currencyValue(transactionValue: TransactionValue, rate: CurrencyValue?) -> CurrencyValue? {
        if let rate = rate, case .coinValue(_, let value) = transactionValue {
            return CurrencyValue(currency: rate.currency, value: value * rate.value)
        }

        return nil
    }

}

extension TransactionsService {

    var allItems: [TransactionItem] {
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

    var syncState: AdapterState? {
        syncStateService.syncState
    }

    var walletFiltersObservable: Observable<(wallets: [TransactionWallet], selected: Int?)> {
        walletFiltersSubject.asObservable()
    }

    var typeFiltersObservable: Observable<(types: [TransactionTypeFilter], selected: Int)> {
        typeFiltersSubject.asObservable()
    }

    var itemsObservable: Observable<[TransactionItem]> {
        itemsSubject.asObservable()
    }

    var updatedItemObservable: Observable<TransactionItem> {
        updatedItemSubject.asObservable()
    }

    var syncStateSignal: Observable<AdapterState?> {
        syncStateSubject.asObservable()
    }

    func set(selectedWalletIndex: Int?) {
        filterHelper.set(selectedWalletIndex: selectedWalletIndex)
        recordsService.set(selectedWallet: filterHelper.selectedWallet)
    }

    func set(selectedTypeIndex: Int) {
        filterHelper.set(selectedTypeIndex: selectedTypeIndex)
        recordsService.set(typeFilter: filterHelper.selectedType)
    }

    func load(count: Int) {
        recordsService.load(count: count)
    }

    func fetchRate(for uid: String) {
        if let item = item(uid: uid), item.currencyValue == nil,
           let transactionValue = item.record.mainValue, case .coinValue(let platformCoin, _) = transactionValue {
            rateService.fetchRate(key: RateKey(coin: platformCoin.coin, date: item.record.date))
        }
    }

    func item(uid: String) -> TransactionItem? {
        queue.sync {
            items.first(where: { $0.record.uid == uid })
        }
    }

}
