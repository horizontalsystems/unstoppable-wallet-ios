import CurrencyKit
import EthereumKit
import CoinKit
import RxSwift
import RxCocoa

class TransactionInfoService {
    private let disposeBag = DisposeBag()

    private let transactionItemUpdatedRelay = PublishRelay<()>()
    private(set) var transactionItem: TransactionItem {
        didSet {
            transactionItemUpdatedRelay.accept(())
        }
    }

    private let adapter: ITransactionsAdapter
    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit
    private let feeCoinProvider: FeeCoinProvider
    private let appConfigProvider: IAppConfigProvider

    private let ratesRelay = PublishRelay<[Coin: CurrencyValue]>()

    init(adapter: ITransactionsAdapter, rateManager: IRateManager, currencyKit: CurrencyKit.Kit, transactionItem: TransactionItem, feeCoinProvider: FeeCoinProvider,
         appConfigProvider: IAppConfigProvider) {
        self.adapter = adapter
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.transactionItem = transactionItem
        self.feeCoinProvider = feeCoinProvider
        self.appConfigProvider = appConfigProvider

        subscribe(disposeBag, adapter.transactionsObservable(coin: nil, filter: .all)) { [weak self] in self?.sync(transactionRecords: $0) }
        subscribe(disposeBag, adapter.lastBlockUpdatedObservable) { [weak self] in self?.syncLastBlockUpdated() }
    }

    private func sync(transactionRecords: [TransactionRecord]) {
        guard let transactionRecord = transactionRecords.first(where: { transactionRecord in transactionItem.record == transactionRecord }) else {
            return
        }

        transactionItem = TransactionItem(record: transactionRecord, lastBlockInfo: adapter.lastBlockInfo, currencyValue: transactionItem.currencyValue)
    }

    private func syncLastBlockUpdated() {
        transactionItem = TransactionItem(record: transactionItem.record, lastBlockInfo: adapter.lastBlockInfo, currencyValue: transactionItem.currencyValue)
    }

}

extension TransactionInfoService {

    var ratesSignal: Signal<[Coin: CurrencyValue]> {
        ratesRelay.asSignal()
    }

    var transactionItemUpdatedObservable: Observable<()> {
        transactionItemUpdatedRelay.asObservable()
    }

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    var testMode: Bool {
        appConfigProvider.testMode
    }

    func fetchRates(coins: [Coin], timestamp: TimeInterval) {
        let baseCurrency = baseCurrency

        let singles: [Single<(coin: Coin, currencyValue: CurrencyValue)>] = coins.map { coin in
            rateManager
                    .historicalRate(coinType: coin.type, currencyCode: baseCurrency.code, timestamp: timestamp)
                    .map { (coin: coin, currencyValue: CurrencyValue(currency: baseCurrency, value: $0)) }
        }

        Single.zip(singles)
                .subscribe { [weak self] (rates: [(coin: Coin, currencyValue: CurrencyValue)]) in
                    var ratesMap = [Coin: CurrencyValue]()
                    for rate in rates {
                        ratesMap[rate.coin] = rate.currencyValue
                    }

                    self?.ratesRelay.accept(ratesMap)
                }
                .disposed(by: disposeBag)
    }

    func rawTransaction(hash: String) -> String? {
        adapter.rawTransaction(hash: hash)
    }

}
