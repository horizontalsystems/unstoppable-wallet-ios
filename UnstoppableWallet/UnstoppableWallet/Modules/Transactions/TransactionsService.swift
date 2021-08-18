import RxSwift
import CurrencyKit

class TransactionsService {
    private var disposeBag = DisposeBag()
    private let recordsService: TransactionRecordsService
    private let syncStateService: TransactionSyncStateService
    private let rateService: HistoricalRateService

    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    private var wallets = [TransactionWallet]()
    private var walletsSubject = BehaviorSubject<[TransactionWallet]>(value: [])

    private var items = [TransactionItem]()
    private var itemsSubject = PublishSubject<[TransactionItem]>()
    private var updatedItemSubject = PublishSubject<TransactionItem>()
    private var syncingSubject = PublishSubject<Bool>()

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager) {
        recordsService = TransactionRecordsService(adapterManager: adapterManager)
        syncStateService = TransactionSyncStateService(adapterManager: adapterManager)
        rateService = HistoricalRateService(ratesManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)

        handle(updatedWallets: walletManager.activeWallets)

        subscribe(disposeBag, walletManager.activeWalletsUpdatedObservable) { [weak self] wallets in self?.handle(updatedWallets: wallets) }
        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] wallets in self?.onAdaptersReady() }

        recordsService.recordsObservable
                .subscribe(onNext: { [weak self] records in self?.handle(records: records) })
                .disposed(by: disposeBag)

        recordsService.updatedRecordObservable
                .subscribe(onNext: { [weak self] record in self?.handle(updatedRecord: record) })
                .disposed(by: disposeBag)

        syncStateService.lastBlockInfoObservable
                .subscribe(onNext: { [weak self] (source, lastBlockInfo) in self?.handle(source: source, lastBlockInfo: lastBlockInfo) })
                .disposed(by: disposeBag)

        syncStateService.syncingObservable
                .subscribe(onNext: { [weak self] syncing in self?.syncingSubject.onNext(syncing) })
                .disposed(by: disposeBag)

        rateService.ratesChangedObservable
                .subscribe(onNext: { [weak self] in self?.handleRatesChanged() })
                .disposed(by: disposeBag)

        rateService.rateUpdatedObservable
                .subscribe(onNext: { [weak self] rate in self?.handle(rate: rate) })
                .disposed(by: disposeBag)
    }

    func groupWalletsBySource(transactionWallets: [TransactionWallet]) -> [TransactionWallet] {
        var groupedWallets = [TransactionWallet]()

        for wallet in transactionWallets {
            switch wallet.source.blockchain {
            case .bitcoin, .bitcoinCash, .litecoin, .dash, .zcash, .bep2: groupedWallets.append(wallet)
            case .ethereum, .binanceSmartChain:
                if !groupedWallets.contains(where: { wallet.source == $0.source }) {
                    groupedWallets.append(TransactionWallet(coin: nil, source: wallet.source))
                }
            }
        }

        return groupedWallets
    }

    private func handle(updatedWallets: [Wallet]) {
        wallets = updatedWallets
                .sorted { wallet, wallet2 in wallet.coin.code < wallet2.coin.code }
                .map { TransactionWallet(coin: $0.coin, source: $0.transactionSource) }

        walletsSubject.onNext(wallets)
    }

    private func onAdaptersReady() {
        let walletsGroupedBySource = groupWalletsBySource(transactionWallets: wallets)

        syncStateService.set(sources: walletsGroupedBySource.map { $0.source })
        recordsService.set(wallets: wallets, walletsGroupedBySource: walletsGroupedBySource)
        recordsService.set(selectedWallet: nil)
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
            if let coinValue = item.record.mainValue, coinValue.coin.type == rate.0.coinType && item.record.date == rate.0.date {
                update(item: item, index: index, currencyValue: _currencyValue(coinValue: coinValue, rate: rate.1))
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
        let currencyValue = record.mainValue.flatMap { coinValue in
            _currencyValue(coinValue: coinValue, rate: rateService.rate(key: RateKey(coinType: coinValue.coin.type, date: record.date)))
        }

        return TransactionItem(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
    }

    private func _currencyValue(coinValue: CoinValue, rate: CurrencyValue?) -> CurrencyValue? {
        rate.flatMap { CurrencyValue(currency: $0.currency, value: coinValue.value * $0.value) }
    }

}

extension TransactionsService {

    var walletsObservable: Observable<[TransactionWallet]> {
        walletsSubject.asObservable()
    }

    var itemsObservable: Observable<[TransactionItem]> {
        itemsSubject.asObservable()
    }

    var updatedItemObservable: Observable<TransactionItem> {
        updatedItemSubject.asObservable()
    }

    var syncingSignal: Observable<Bool> {
        syncingSubject.asObservable()
    }

    func set(selectedCoinFilterIndex: Int?) {
        guard let index = selectedCoinFilterIndex else {
            recordsService.set(selectedWallet: nil)
            return
        }

        if wallets.count > index {
            recordsService.set(selectedWallet: wallets[index])
        }
    }

    func set(typeFilter: TransactionTypeFilter) {
        recordsService.set(typeFilter: typeFilter)
    }

    func load(count: Int) {
        recordsService.load(count: count)
    }

    func fetchRate(for uid: String) {
        if let item = item(uid: uid), item.currencyValue == nil, let coinValue = item.record.mainValue {
            rateService.fetchRate(key: RateKey(coinType: coinValue.coin.type, date: item.record.date))
        }
    }

    func item(uid: String) -> TransactionItem? {
        items.first(where: { $0.record.uid == uid })
    }

}
