import Foundation

class TransactionsInteractor {
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
    }

}

extension TransactionsInteractor: ITransactionsInteractor {

    func set(coin: Coin?) {
        dataSource.set(coin: coin)
    }

    var recordsCount: Int {
        return dataSource.count
    }

    func record(forIndex index: Int) -> TransactionRecord {
        return dataSource.record(forIndex: index)
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
