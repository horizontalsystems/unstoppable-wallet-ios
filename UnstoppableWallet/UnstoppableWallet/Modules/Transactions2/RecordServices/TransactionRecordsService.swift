import RxSwift

class TransactionRecordsService {
    private var disposeBag = DisposeBag()
    private var recordsDisposeBag = DisposeBag()

    private var singleRecordServices = [TransactionWallet: ITransactionRecordService]()
    private var allRecordsService: ITransactionRecordService? = nil
    private var activeService: ITransactionRecordService? = nil
    private var adapterManager: TransactionAdapterManager

    private var recordsSubject = PublishSubject<[TransactionRecord]>()
    private var updatedRecordSubject = PublishSubject<TransactionRecord>()

    init(adapterManager: TransactionAdapterManager) {
        self.adapterManager = adapterManager
    }

}

extension TransactionRecordsService {

    var recordsObservable: Observable<[TransactionRecord]> {
        recordsSubject.asObservable()
    }

    var updatedRecordObservable: Observable<TransactionRecord> {
        updatedRecordSubject.asObservable()
    }

    func set(wallets: [TransactionWallet], walletsGroupedBySource: [TransactionWallet]) {
        for wallet in wallets {
            if let adapter = adapterManager.adapter(for: wallet.source) {
                let dataSource = TransactionRecordDataSource(wallet: wallet, adapter: adapter)
                singleRecordServices[wallet] = SingleWalletRecordService(dataSource: dataSource)
            }
        }

        let dataSources: [TransactionRecordDataSource] = walletsGroupedBySource.compactMap { wallet in
            if let adapter = adapterManager.adapter(for: wallet.source) {
                return TransactionRecordDataSource(wallet: wallet, adapter: adapter)
            }

            return nil
        }

        allRecordsService = AllWalletsRecordService(dataSources: dataSources)
    }

    func set(selectedWallet: TransactionWallet?) {
        if let wallet = selectedWallet {
            activeService = singleRecordServices[wallet]
        } else {
            activeService = allRecordsService
        }

        recordsDisposeBag = DisposeBag()

        activeService?.updatedRecordObservable
                .subscribe(onNext: { [weak self] record in self?.updatedRecordSubject.onNext(record) })
                .disposed(by: recordsDisposeBag)

        activeService?.recordsObservable
                .subscribe(onNext: { [weak self] records in self?.recordsSubject.onNext(records) })
                .disposed(by: recordsDisposeBag)

        activeService?.load(count: TransactionsModule2.pageLimit, reload: true)
    }

    func set(filter: TransactionsModule2.TypeFilter) {
        for service in singleRecordServices.values {
            service.set(filter: filter)
        }

        allRecordsService?.set(filter: filter)
    }

    func load(count: Int) {
        activeService?.load(count: count, reload: false)
    }

}
