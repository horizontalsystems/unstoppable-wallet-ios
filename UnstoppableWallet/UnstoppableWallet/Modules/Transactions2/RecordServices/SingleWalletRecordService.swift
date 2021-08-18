import RxSwift

class SingleWalletRecordService {
    private let disposeBag = DisposeBag()

    private let dataSource: TransactionRecordDataSource

    private var recordsSubject = PublishSubject<[TransactionRecord]>()
    private var updatedRecordSubject = PublishSubject<TransactionRecord>()
    private var requestedCount: Int = 0

    init(dataSource: TransactionRecordDataSource) {
        self.dataSource = dataSource

        dataSource.updatedRecordsObservable
                .subscribe(onNext: { [weak self] update in self?.handle(recordsUpdate: update) })
                .disposed(by: disposeBag)
    }

    private func handle(recordsUpdate: TransactionRecordDataSource.RecordsUpdate) {
        switch recordsUpdate {
        case .single(let record): updatedRecordSubject.onNext(record)
        case .list(let records): recordsSubject.onNext(dataSource.records(count: requestedCount))
        }
    }

}

extension SingleWalletRecordService: ITransactionRecordService {

    var recordsObservable: Observable<[TransactionRecord]> {
        recordsSubject.asObservable()
    }

    var updatedRecordObservable: Observable<TransactionRecord> {
        updatedRecordSubject.asObservable()
    }

    func set(requestedCount: Int) {
        self.requestedCount = requestedCount
    }

    func load(count: Int, reload: Bool) {
        if !reload && requestedCount >= count {
            return
        }
        set(requestedCount: count)

        dataSource
                .recordsSingle(count: requestedCount)
                .subscribe(onSuccess: { [weak self] records in
                    self?.recordsSubject.onNext(records)
                })
                .disposed(by: disposeBag)
    }

    func set(typeFilter: TransactionsModule2.TypeFilter) {
        dataSource.set(typeFilter: typeFilter)
    }

}
