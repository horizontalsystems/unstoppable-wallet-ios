import RxSwift

class TransactionsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let exchangeRateManager: IRateManager
    private let dataSource: ITransactionRecordDataSource

    private let refreshTimeout: Double

    init(walletManager: IWalletManager, exchangeRateManager: IRateManager, dataSource: ITransactionRecordDataSource, refreshTimeout: Double = 2) {
        self.walletManager = walletManager
        self.exchangeRateManager = exchangeRateManager
        self.dataSource = dataSource

        self.refreshTimeout = refreshTimeout

        Observable.merge(walletManager.wallets.map { $0.adapter.lastBlockHeightSubject })
                .throttle(3, latest: true, scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.delegate?.didUpdateDataSource()
                })
                .disposed(by: disposeBag)
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func set(coinCode: CoinCode?) {
        dataSource.set(coinCode: coinCode)
    }

    var recordsCount: Int {
        return dataSource.count
    }

    func record(forIndex index: Int) -> TransactionRecord {
        return dataSource.record(forIndex: index)
    }

    func retrieveFilters() {
        let coins = walletManager.wallets.map { $0.coinCode }
        delegate?.didRetrieve(filters: coins)
    }

}

extension TransactionsInteractor: ITransactionRecordDataSourceDelegate {

    func onUpdateResults() {
        delegate?.didUpdateDataSource()
    }

}
