import RxSwift
import MarketKit

class TransactionRecordDataSource {
    enum RecordsUpdate {
        case single(record: TransactionRecord)
        case list(records: [TransactionRecord])
    }

    private var disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.tx_data_source", qos: .background)

    private let coin: PlatformCoin?
    private var filter: TransactionTypeFilter = .all
    private let adapter: ITransactionsAdapter
    private var records = [TransactionRecord]()
    private var allShown = false

    private var updatedRecordsSubject = PublishSubject<RecordsUpdate>()

    init(coin: PlatformCoin?, adapter: ITransactionsAdapter) {
        self.coin = coin
        self.adapter = adapter

        subscribe()
    }

    private func subscribe() {
        disposeBag = DisposeBag()

        adapter
                .transactionsObservable(coin: coin, filter: filter)
                .subscribe(onNext: { [weak self] records in
                    self?.queue.async { [weak self] in
                        self?.handle(records: records)
                    }
                })
                .disposed(by: disposeBag)
    }

    private func handle(records: [TransactionRecord]) {
        var updatedRecords = [TransactionRecord]()
        var hasNewRecords = false

        for record in records {
            if let index = self.records.index(of: record) {
                self.records[index] = record
                updatedRecords.append(record)
            } else {
                self.records.append(record)
                hasNewRecords = true
            }
        }

        self.records.sort()
        self.records.reverse()

        if hasNewRecords {
            updatedRecordsSubject.onNext(RecordsUpdate.list(records: self.records))
        } else {
            for record in updatedRecords {
                updatedRecordsSubject.onNext(RecordsUpdate.single(record: record))
            }
        }
    }

}

extension TransactionRecordDataSource {

    var updatedRecordsObservable: Observable<RecordsUpdate> {
        updatedRecordsSubject.asObservable()
    }

    func records(count: Int) -> [TransactionRecord] {
        Array(records.prefix(count))
    }

    func recordsSingle(count: Int) -> Single<[TransactionRecord]> {
        let neededRecordsCount = count - records.count

        if neededRecordsCount <= 0 || allShown {
            return Single.just(records(count: count))
        } else {
            return adapter
                    .transactionsSingle(from: records.last, coin: coin, filter: filter, limit: neededRecordsCount)
                    .map { [weak self] records in
                        if records.count < neededRecordsCount {
                            self?.allShown = true
                        }

                        self?.records.append(contentsOf: records)
                        return self?.records(count: count) ?? []
                    }
        }
    }

    func set(typeFilter: TransactionTypeFilter) {
        filter = typeFilter
        records = []
        allShown = false
        subscribe()
    }

}
