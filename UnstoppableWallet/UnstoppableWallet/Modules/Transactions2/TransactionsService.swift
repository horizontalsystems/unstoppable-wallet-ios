import RxSwift
import RxCocoa
import CurrencyKit

class TransactionsService {
    private var disposeBag = DisposeBag()
    private let recordsService: TransactionRecordsService
    private let syncStateService: TransactionSyncStateService
    private let rateService: HistoricalRateService

    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    private var wallets = [TransactionWallet]()
    private var walletsRelay = BehaviorRelay<[TransactionWallet]>(value: [])

    private var items = [TransactionsModule2.Item]()
    private var itemsRelay = PublishRelay<[TransactionsModule2.Item]>()
    private var updatedItemRelay = PublishRelay<TransactionsModule2.Item>()
    private var syncingRelay = PublishRelay<Bool>()

    init(walletManager: WalletManager, adapterManager: TransactionAdapterManager) {
        recordsService = TransactionRecordsService(adapterManager: adapterManager)
        syncStateService = TransactionSyncStateService(adapterManager: adapterManager)
        rateService = HistoricalRateService(ratesManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)

        handle(updatedWallets: walletManager.activeWallets)
        walletManager.activeWalletsUpdatedObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] wallets in self?.handle(updatedWallets: wallets) })
                .disposed(by: disposeBag)

        adapterManager.adaptersReadyObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] wallets in self?.onAdaptersReady() })
                .disposed(by: disposeBag)

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
                .subscribe(onNext: { [weak self] syncing in self?.syncingRelay.accept(syncing) })
                .disposed(by: disposeBag)

        rateService.ratesExpiredObservable
                .subscribe(onNext: { [weak self] in self?.handleRatesExpired() })
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

        walletsRelay.accept(wallets)

        print("MainService saved \(wallets.count) wallets")
    }

    private func onAdaptersReady() {
        let walletsGroupedBySource = groupWalletsBySource(transactionWallets: wallets)

        syncStateService.set(sources: walletsGroupedBySource.map { $0.source })
        recordsService.set(wallets: wallets, walletsGroupedBySource: walletsGroupedBySource)
        recordsService.set(selectedWallet: nil)

        print("MainService set \(wallets.count) wallets and \(walletsGroupedBySource.count) allWallets")
    }

    private func handle(records: [TransactionRecord]) {
        print("MainService received \(records.count) records: \(records.map { $0.transactionHash })")
        items = records.map { record in
            createItem(from: record)
        }

        itemsRelay.accept(items)
    }

    private func handleRatesExpired() {
        print("MainService received baseCurrency update)")
        for (index, item) in items.enumerated() {
            if item.record.mainValue != nil {
                items[index] = createItem(from: item.record)
            }
        }

        itemsRelay.accept(items)
    }

    private func handle(updatedRecord record: TransactionRecord) {
        print("MainService received update for \(record.transactionHash) transaction")
        for (index, item) in items.enumerated() {
            if item.record.uid == record.uid {
                update(item: item, index: index, record: record)
            }
        }
    }

    private func handle(source: TransactionSource, lastBlockInfo: LastBlockInfo) {
        print("MainService received source: \(source) lastBlockInfo: \(lastBlockInfo)")
        for (index, item) in items.enumerated() {
            if item.record.source == source && item.record.changedBy(oldBlockInfo: item.lastBlockInfo, newBlockInfo: lastBlockInfo) {
                print("Found changed item. old: \(item.lastBlockInfo) \(item.record.status(lastBlockHeight: item.lastBlockInfo?.height)); new: \(lastBlockInfo) \(item.record.status(lastBlockHeight: lastBlockInfo.height))")
                print("\(item.record.status(lastBlockHeight: item.lastBlockInfo?.height) == item.record.status(lastBlockHeight: lastBlockInfo.height))")

                update(item: item, index: index, lastBlockInfo: lastBlockInfo)
            }
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        print("MainService received rate: \(rate.0) \(rate.1)")
        for (index, item) in items.enumerated() {
            if let coinValue = item.record.mainValue, coinValue.coin.type == rate.0.coinType && item.record.date == rate.0.date {
                update(item: item, index: index, currencyValue: _currencyValue(coinValue: coinValue, rate: rate.1))
            }
        }
    }

    private func update(item: TransactionsModule2.Item, index: Int, record: TransactionRecord? = nil, lastBlockInfo: LastBlockInfo? = nil, currencyValue: CurrencyValue? = nil) {
        let record = record ?? item.record
        let lastBlockInfo = lastBlockInfo ?? item.lastBlockInfo
        let currencyValue = currencyValue ?? item.currencyValue

        let item = TransactionsModule2.Item(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
        items[index] = item
        updatedItemRelay.accept(item)
    }

    private func createItem(from record: TransactionRecord) -> TransactionsModule2.Item {
        let lastBlockInfo = syncStateService.lastBlockInfo(source: record.source)
        let currencyValue = record.mainValue.flatMap { coinValue in
            _currencyValue(coinValue: coinValue, rate: rateService.rate(key: RateKey(coinType: coinValue.coin.type, date: record.date)))
        }

        return TransactionsModule2.Item(record: record, lastBlockInfo: lastBlockInfo, currencyValue: currencyValue)
    }

    private func _currencyValue(coinValue: CoinValue, rate: CurrencyValue?) -> CurrencyValue? {
        rate.flatMap { CurrencyValue(currency: $0.currency, value: coinValue.value * $0.value) }
    }

}

extension TransactionsService {

    var walletsDriver: Driver<[TransactionWallet]> {
        walletsRelay.asDriver()
    }

    var itemsDriverSignal: Signal<[TransactionsModule2.Item]> {
        itemsRelay.asSignal()
    }

    var updatedItemSignal: Signal<TransactionsModule2.Item> {
        updatedItemRelay.asSignal()
    }

    var syncingSignal: Signal<Bool> {
        syncingRelay.asSignal()
    }

    func set(selectedCoinFilterIndex: Int?) {
        guard let index = selectedCoinFilterIndex else {
            recordsService.set(selectedWallet: nil)
            return
        }

        print("set(selectedCoinFilterIndex: Int?) => wallets.count: \(wallets.count)")
        if wallets.count > index {
            recordsService.set(selectedWallet: wallets[index])
        }
    }

    func load(count: Int) {
        recordsService.load(count: count)
    }

    func fetchRate(for uid: String) {
        if let item = items.first(where: { $0.record.uid == uid }), item.currencyValue == nil, let coinValue = item.record.mainValue {
            rateService.fetchRate(key: RateKey(coinType: coinValue.coin.type, date: item.record.date))
        }
    }

}
