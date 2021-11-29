import RxSwift

class TransactionSyncStateService {
    private var disposeBag = DisposeBag()

    private var adapterManager: TransactionAdapterManager
    private var adapters = [TransactionSource: ITransactionsAdapter]()
    private(set) var syncState: AdapterState? = nil {
        didSet {
            if syncState != oldValue {
                syncStateSubject.onNext(syncState)
            }
        }
    }

    private var lastBlockInfoSubject = PublishSubject<(TransactionSource, LastBlockInfo)>()
    private var syncStateSubject = PublishSubject<AdapterState?>()

    init(adapterManager: TransactionAdapterManager) {
        self.adapterManager = adapterManager
    }

    func stateUpdated() {
        for adapter in adapters.values {
            switch adapter.transactionState {
            case .syncing, .notSynced, .searchingTxs:
                syncState = adapter.transactionState
                return
            case .synced: ()
            }
        }

        syncState = .synced
    }

}

extension TransactionSyncStateService {

    var lastBlockInfoObservable: Observable<(TransactionSource, LastBlockInfo)> {
        lastBlockInfoSubject.asObservable()
    }

    var syncStateObservable: Observable<AdapterState?> {
        syncStateSubject.asObservable()
    }

    func lastBlockInfo(source: TransactionSource) -> LastBlockInfo? {
        adapters[source]?.lastBlockInfo
    }

    func set(sources: [TransactionSource]) {
        disposeBag = DisposeBag()
        adapters = [:]

        for source in sources {
            if let adapter = adapterManager.adapter(for: source) {
                adapters[source] = adapter

                adapter.lastBlockUpdatedObservable
                        .subscribe(onNext: { [weak self] in
                            adapter.lastBlockInfo.flatMap {
                                self?.lastBlockInfoSubject.onNext((source, $0))
                            }
                        })
                        .disposed(by: disposeBag)

                adapter.transactionStateUpdatedObservable
                        .subscribe(onNext: { [weak self] in self?.stateUpdated() })
                        .disposed(by: disposeBag)
            }
        }
    }

}
