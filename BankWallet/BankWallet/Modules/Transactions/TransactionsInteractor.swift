import RxSwift
import Foundation

class TransactionsInteractor {
    private let disposeBag = DisposeBag()

    weak var delegate: ITransactionsInteractorDelegate?

    private let walletManager: IWalletManager
    private let exchangeRateManager: IRateManager
    private let currencyManager: ICurrencyManager
    private let dataSource: ITransactionRecordDataSource

    private let refreshTimeout: Double

    init(walletManager: IWalletManager, exchangeRateManager: IRateManager, currencyManager: ICurrencyManager, dataSource: ITransactionRecordDataSource, refreshTimeout: Double = 2) {
        self.walletManager = walletManager
        self.exchangeRateManager = exchangeRateManager
        self.currencyManager = currencyManager
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

    func set(coin: Coin?) {
        dataSource.set(coin: coin)
    }

    var baseCurrency: Currency {
        return currencyManager.baseCurrency
    }

    var recordsCount: Int {
        return dataSource.count
    }

    func record(forIndex index: Int) -> TransactionRecord {
        return dataSource.record(forIndex: index)
    }

    func adapter(forCoin coin: Coin) -> IAdapter? {
        return walletManager.wallets.first(where: { $0.coin == coin })?.adapter
    }

    func retrieveFilters() {
        let coins = walletManager.wallets.map { $0.coin }
        delegate?.didRetrieve(filters: coins)
    }

    func refresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + refreshTimeout, execute: {
            self.delegate?.didRefresh()
        })
    }

}

extension TransactionsInteractor: ITransactionRecordDataSourceDelegate {

    func onUpdateResults() {
        delegate?.didUpdateDataSource()
    }

}
