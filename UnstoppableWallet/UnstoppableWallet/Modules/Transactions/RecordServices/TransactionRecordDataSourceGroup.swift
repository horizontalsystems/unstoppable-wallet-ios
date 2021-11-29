import RxSwift

class TransactionRecordDataSourceGroup {
    private var disposeBag = DisposeBag()

    private var recordsSubject = PublishSubject<[TransactionRecord]>()
    private var updatedRecordSubject = PublishSubject<TransactionRecord>()
    private var requestedCount: Int = 0

    let dataSources: [TransactionRecordDataSource]

    init(dataSources: [TransactionRecordDataSource]) {
        self.dataSources = dataSources

        for dataSource in dataSources {
            dataSource.updatedRecordsObservable
                    .subscribe(onNext: { [weak self] update in self?.handle(recordsUpdate: update) })
                    .disposed(by: disposeBag)
        }
    }

    private func emit(records: [[TransactionRecord]]) {
        var allRecords = [TransactionRecord]()

        for _records in records {
            allRecords.append(contentsOf: _records)
        }

        let sortedRecords = Array(allRecords.sorted().reversed().prefix(requestedCount))

        recordsSubject.onNext(sortedRecords)
    }

    private func handle(recordsUpdate update: TransactionRecordDataSource.RecordsUpdate) {
        switch update {
        case .single(let record): updatedRecordSubject.onNext(record)
        case .list: emit(records: dataSources.map { $0.records(count: requestedCount) })
        }
    }

}

extension TransactionRecordDataSourceGroup {

    var recordsObservable: Observable<[TransactionRecord]> {
        recordsSubject.asObservable()
    }

    var updatedRecordObservable: Observable<TransactionRecord> {
        updatedRecordSubject.asObservable()
    }

    func load(count: Int, reload: Bool) {
        if !reload && requestedCount >= count {
            return
        }
        requestedCount = count

        Single<[TransactionRecord]>
                .zip(dataSources.map { $0.recordsSingle(count: count) })
                .subscribe(onSuccess: { [weak self] records in
                    self?.emit(records: records)
                })
                .disposed(by: disposeBag)
    }

    func set(typeFilter: TransactionTypeFilter) {
        for dataSource in dataSources {
            dataSource.set(typeFilter: typeFilter)
        }
    }

}
