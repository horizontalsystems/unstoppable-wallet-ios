import CurrencyKit
import EthereumKit
import MarketKit
import RxSwift

class TransactionInfoService {
    private let disposeBag = DisposeBag()

    private let adapter: ITransactionsAdapter
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private var rates = [Coin: CurrencyValue]()
    private var transactionRecord: TransactionRecord

    private let transactionInfoItemSubject = PublishSubject<TransactionInfoItem>()

    init(transactionRecord: TransactionRecord, adapter: ITransactionsAdapter, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.transactionRecord = transactionRecord
        self.adapter = adapter
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        subscribe(disposeBag, adapter.transactionsObservable(token: nil, filter: .all)) { [weak self] in self?.sync(transactionRecords: $0) }
        subscribe(disposeBag, adapter.lastBlockUpdatedObservable) { [weak self] in self?.syncLastBlockUpdated() }

        fetchRates()
    }

    private var coinsForRates: [Coin] {
        var coins = [Coin?]()

        switch transactionRecord {
        case let tx as EvmIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as EvmOutgoingTransactionRecord: coins.append(tx.value.coin)
        case let tx as SwapTransactionRecord:
            coins.append(tx.valueIn.coin)
            tx.valueOut.flatMap { coins.append($0.coin) }

        case let tx as UnknownSwapTransactionRecord:
            tx.valueIn.flatMap { coins.append($0.coin) }
            tx.valueOut.flatMap { coins.append($0.coin) }

        case let tx as ApproveTransactionRecord: coins.append(tx.value.coin)
        case let tx as ContractCallTransactionRecord:
            coins.append(contentsOf: tx.incomingEvents.map({ $0.value.coin }))
            coins.append(contentsOf: tx.outgoingEvents.map({ $0.value.coin }))

        case let tx as ExternalContractCallTransactionRecord:
            coins.append(contentsOf: tx.incomingEvents.map({ $0.value.coin }))
            coins.append(contentsOf: tx.outgoingEvents.map({ $0.value.coin }))

        case let tx as BitcoinIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as BitcoinOutgoingTransactionRecord:
            tx.fee.flatMap { coins.append($0.coin) }
            coins.append(tx.value.coin)

        case let tx as BinanceChainIncomingTransactionRecord: coins.append(tx.value.coin)
        case let tx as BinanceChainOutgoingTransactionRecord:
            coins.append(tx.fee.coin)
            coins.append(tx.value.coin)

        default: ()
        }

        if let evmTransaction = transactionRecord as? EvmTransactionRecord, evmTransaction.ownTransaction, let fee = evmTransaction.fee {
            coins.append(fee.coin)
        }

        return Array(Set(coins.compactMap({ $0 })))
    }

    private func fetchRates() {
        let baseCurrency = currencyKit.baseCurrency

        let singles: [Single<(coin: Coin, currencyValue: CurrencyValue)>] = coinsForRates.map { coin in
            let coinUid = coin.uid
            let currencyCode = baseCurrency.code
            let timestamp = transactionRecord.date.timeIntervalSince1970

            let single: Single<Decimal>

            if let rate = marketKit.coinHistoricalPriceValue(coinUid: coinUid, currencyCode: currencyCode, timestamp: timestamp) {
                single = Single.just(rate)
            } else {
                single = marketKit.coinHistoricalPriceValueSingle(coinUid: coinUid, currencyCode: currencyCode, timestamp: timestamp)
            }

            return single.map {
                (coin: coin, currencyValue: CurrencyValue(currency: baseCurrency, value: $0))
            }
        }

        Single.zip(singles)
                .subscribe { [weak self] (rates: [(coin: Coin, currencyValue: CurrencyValue)]) in
                    var ratesMap = [Coin: CurrencyValue]()
                    for rate in rates {
                        ratesMap[rate.coin] = rate.currencyValue
                    }

                    self?.updateRates(rates: ratesMap)
                }
                .disposed(by: disposeBag)
    }

    private func sync(transactionRecords: [TransactionRecord]) {
        guard let transactionRecord = transactionRecords.first(where: { self.transactionRecord == $0 }) else {
            return
        }

        self.transactionRecord = transactionRecord
        transactionInfoItemSubject.onNext(item)
    }

    private func syncLastBlockUpdated() {
        transactionInfoItemSubject.onNext(item)
    }

    private func updateRates(rates: [Coin: CurrencyValue]) {
        self.rates = rates
        transactionInfoItemSubject.onNext(item)
    }

}

extension TransactionInfoService {

    var item: TransactionInfoItem {
        TransactionInfoItem(
                record: transactionRecord,
                lastBlockInfo: adapter.lastBlockInfo,
                rates: rates,
                explorerTitle: adapter.explorerTitle,
                explorerUrl: adapter.explorerUrl(transactionHash: transactionRecord.transactionHash)
        )
    }

    var transactionItemUpdatedObserver: Observable<TransactionInfoItem> {
        transactionInfoItemSubject.asObservable()
    }

    func rawTransaction() -> String? {
        adapter.rawTransaction(hash: transactionRecord.transactionHash)
    }

}
