import RxSwift

class TransactionManager {
    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private let storage: ITransactionRecordStorage
    private let rateSyncer: ITransactionRateSyncer
    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private let wordsManager: IWordsManager

    init(storage: ITransactionRecordStorage, rateSyncer: ITransactionRateSyncer, walletManager: IWalletManager, currencyManager: ICurrencyManager, wordsManager: IWordsManager, reachabilityManager: IReachabilityManager) {
        self.storage = storage
        self.rateSyncer = rateSyncer
        self.walletManager = walletManager
        self.currencyManager = currencyManager
        self.wordsManager = wordsManager

        resubscribeToAdapters()

        walletManager.walletsSubject
                .subscribe(onNext: { [weak self] _ in
                    self?.resubscribeToAdapters()
                })
                .disposed(by: disposeBag)

        currencyManager.subject
                .subscribe(onNext: { [weak self] _ in
                    self?.handleCurrencyChange()
                })
                .disposed(by: disposeBag)

        wordsManager.loggedInSubject
                .subscribe(onNext: { [weak self] loggedIn in
                    if !loggedIn {
                        self?.clear()
                    }
                })
                .disposed(by: disposeBag)

        reachabilityManager.subject
                .subscribe(onNext: { [weak self] connected in
                    if connected {
                        self?.syncRates()
                    }
                })
                .disposed(by: disposeBag)
    }

    private func resubscribeToAdapters() {
        adaptersDisposeBag = DisposeBag()

        walletManager.wallets.forEach { wallet in
            wallet.adapter.transactionRecordsSubject
                    .subscribe(onNext: { [weak self] records in
                        self?.handle(records: records, forCoin: wallet.coin)
                    })
                    .disposed(by: adaptersDisposeBag)
        }
    }

    private func handle(records: [TransactionRecord], forCoin coin: Coin) {
        records.forEach { record in
            record.coin = coin
        }

        storage.update(records: records)
        syncRates()
    }

    private func handleCurrencyChange() {
        storage.clearRates()
        syncRates()
    }

    private func syncRates() {
        rateSyncer.sync(currencyCode: currencyManager.baseCurrency.code)
    }

    private func clear() {
        storage.clearRecords()
    }

}

extension TransactionManager: ITransactionManager {
}
