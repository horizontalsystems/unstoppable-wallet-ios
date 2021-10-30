import RxSwift

class TransactionRecordsService {
    private var disposeBag = DisposeBag()
    private var recordsDisposeBag = DisposeBag()

    private var singleDataSourceGroups = [TransactionWallet: TransactionRecordDataSourceGroup]()
    private var allDataSourcesGroup: TransactionRecordDataSourceGroup
    private var activeGroup: TransactionRecordDataSourceGroup
    private var adapterManager: TransactionAdapterManager

    private var recordsSubject = PublishSubject<[TransactionRecord]>()
    private var updatedRecordSubject = PublishSubject<TransactionRecord>()

    private var requestedCount: Int = 0

    init(adapterManager: TransactionAdapterManager) {
        self.adapterManager = adapterManager

        let group = TransactionRecordDataSourceGroup(dataSources: [])
        allDataSourcesGroup = group
        activeGroup = group
    }

    private func generateDataSources(wallets: [TransactionWallet]) -> [TransactionWallet: TransactionRecordDataSource] {
        var dataSources = [TransactionWallet: TransactionRecordDataSource]()

        // Old data sources
        for group in (singleDataSourceGroups.values + [allDataSourcesGroup]) {
            for dataSource in group.dataSources {
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
        var newGroups = [TransactionWallet: TransactionRecordDataSourceGroup]()

        for wallet in wallets {
            if let group = singleDataSourceGroups[wallet] {
                newGroups[wallet] = group
            } else if let dataSource = dataSources[wallet] {
                newGroups[wallet] = TransactionRecordDataSourceGroup(dataSources: [dataSource])
            }
        }

        allDataSourcesGroup = TransactionRecordDataSourceGroup(dataSources: walletsGroupedBySource.compactMap { dataSources[$0] })
        singleDataSourceGroups = newGroups
    }

    func set(selectedWallet: TransactionWallet?) {
        let selectedGroup: TransactionRecordDataSourceGroup

        if let wallet = selectedWallet, let group = singleDataSourceGroups[wallet] {
            selectedGroup = group
        } else {
            selectedGroup = allDataSourcesGroup
        }

        guard selectedGroup.dataSources.map({ $0.wallet }) != activeGroup.dataSources.map({ $0.wallet }) else {
            return
        }

        activeGroup = selectedGroup
        recordsDisposeBag = DisposeBag()

        activeGroup.updatedRecordObservable
                .subscribe(onNext: { [weak self] record in self?.updatedRecordSubject.onNext(record) })
                .disposed(by: recordsDisposeBag)

        activeGroup.recordsObservable
                .subscribe(onNext: { [weak self] records in self?.recordsSubject.onNext(records) })
                .disposed(by: recordsDisposeBag)

        activeGroup.load(count: TransactionsModule.pageLimit, reload: true)
    }

    func set(typeFilter: TransactionTypeFilter) {
        for group in singleDataSourceGroups.values {
            group.set(typeFilter: typeFilter)
        }

        allDataSourcesGroup.set(typeFilter: typeFilter)
        activeGroup.load(count: TransactionsModule.pageLimit, reload: true)
    }

    func load(count: Int) {
        activeGroup.load(count: count, reload: false)
    }

}
