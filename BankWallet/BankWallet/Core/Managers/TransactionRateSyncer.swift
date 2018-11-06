import RxSwift

class TransactionRateSyncer {
    private var disposeBag = DisposeBag()

    private let storage: ITransactionRecordStorage
    private let networkManager: IRateNetworkManager

    private let async: Bool

    init(storage: ITransactionRecordStorage, networkManager: IRateNetworkManager, async: Bool = true) {
        self.storage = storage
        self.networkManager = networkManager
        self.async = async
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

            var observable = networkManager.getRate(coin: record.coin, currencyCode: currencyCode, date: date)

            if async {
                observable = observable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
            }

            observable
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
