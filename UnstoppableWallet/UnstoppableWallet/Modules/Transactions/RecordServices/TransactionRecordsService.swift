import RxSwift

class TransactionRecordsService {
    private var disposeBag = DisposeBag()
    private var recordsDisposeBag = DisposeBag()

    private var singleRecordServices = [TransactionWallet: ITransactionRecordService]()
    private var allRecordsService: ITransactionRecordService
    private var activeService: ITransactionRecordService
    private var adapterManager: TransactionAdapterManager

    private var recordsSubject = PublishSubject<[TransactionRecord]>()
    private var updatedRecordSubject = PublishSubject<TransactionRecord>()

    private var requestedCount: Int = 0

    init(adapterManager: TransactionAdapterManager) {
        self.adapterManager = adapterManager

        let service = TransactionRecordDataSourceGroup(dataSources: [])
        allRecordsService = service
        activeService = service
    }

    private func generateDataSources(wallets: [TransactionWallet]) -> [TransactionWallet: TransactionRecordDataSource] {
        var dataSources = [TransactionWallet: TransactionRecordDataSource]()

        // Old data sources
        for service in (singleRecordServices.values + [allRecordsService]) {
            for dataSource in service.dataSources {
                dataSources[dataSource.wallet] = dataSource
            }
        }

        // New data sources
        for wallet in wallets {
            if dataSources[wallet] == nil, let adapter = adapterManager.adapter(for: wallet.source) {
                dataSources[wallet] = TransactionRecordDataSource(wallet: wallet, adapter: adapter)
            }
        }

        return dataSources
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
        let dataSources = generateDataSources(wallets: Array(Set(wallets + walletsGroupedBySource)))
        var newServices = [TransactionWallet: ITransactionRecordService]()

        for wallet in wallets {
            if let service = singleRecordServices[wallet] {
                newServices[wallet] = service
            } else if let dataSource = dataSources[wallet] {
                newServices[wallet] = TransactionRecordDataSourceGroup(dataSources: [dataSource])
            }
        }

        allRecordsService = TransactionRecordDataSourceGroup(dataSources: walletsGroupedBySource.compactMap { dataSources[$0] })
        singleRecordServices = newServices

        set(selectedWallet: nil)
    }

    func set(selectedWallet: TransactionWallet?) {
        if let wallet = selectedWallet, let service = singleRecordServices[wallet] {
            activeService = service
        } else {
            activeService = allRecordsService
        }

        recordsDisposeBag = DisposeBag()

        activeService.updatedRecordObservable
                .subscribe(onNext: { [weak self] record in self?.updatedRecordSubject.onNext(record) })
                .disposed(by: recordsDisposeBag)

        activeService.recordsObservable
                .subscribe(onNext: { [weak self] records in self?.recordsSubject.onNext(records) })
                .disposed(by: recordsDisposeBag)

        activeService.load(count: TransactionsModule.pageLimit, reload: true)
    }

    func set(typeFilter: TransactionTypeFilter) {
        for service in singleRecordServices.values {
            service.set(typeFilter: typeFilter)
        }

        allRecordsService.set(typeFilter: typeFilter)
        activeService.load(count: TransactionsModule.pageLimit, reload: true)
    }

    func load(count: Int) {
        activeService.load(count: count, reload: false)
    }

}
