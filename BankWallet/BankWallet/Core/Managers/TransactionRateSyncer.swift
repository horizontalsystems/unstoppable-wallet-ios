import RxSwift

class TransactionRateSyncer {
    private var disposeBag = DisposeBag()

    private let storage: ITransactionRecordStorage
    private let networkManager: IRateNetworkManager

    private let scheduler: ImmediateSchedulerType

    init(storage: ITransactionRecordStorage, networkManager: IRateNetworkManager, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.storage = storage
        self.networkManager = networkManager
        self.scheduler = scheduler
    }

}

extension TransactionRateSyncer: ITransactionRateSyncer {

    func sync(currencyCode: String) {
        for record in storage.nonFilledRecords {
            guard record.timestamp != 0 else {
                continue
            }

            let hash = record.transactionHash
            let date = Date(timeIntervalSince1970: Double(record.timestamp))

            networkManager.getRate(coin: record.coin, currencyCode: currencyCode, date: date)
                    .subscribeOn(scheduler)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] value in
                        self?.storage.set(rate: value, transactionHash: hash)
                    })
                    .disposed(by: disposeBag)
        }
    }

    func cancelCurrentSync() {
        disposeBag = DisposeBag()
    }

}
