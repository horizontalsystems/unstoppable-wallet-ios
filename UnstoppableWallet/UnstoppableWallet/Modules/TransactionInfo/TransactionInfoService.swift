import CurrencyKit
import EvmKit
import MarketKit
import RxSwift

class TransactionInfoService {
    private let disposeBag = DisposeBag()

    private let adapter: ITransactionsAdapter
    private let currencyKit: CurrencyKit.Kit
    private let rateService: HistoricalRateService
    private let nftMetadataService: NftMetadataService

    private var transactionRecord: TransactionRecord
    private var rates = [RateKey: CurrencyValue]()
    private var nftMetadata = [NftUid: NftAssetBriefMetadata]()

    private let transactionInfoItemSubject = PublishSubject<Item>()

    init(transactionRecord: TransactionRecord, adapter: ITransactionsAdapter, currencyKit: CurrencyKit.Kit, rateService: HistoricalRateService, nftMetadataService: NftMetadataService) {
        self.transactionRecord = transactionRecord
        self.adapter = adapter
        self.currencyKit = currencyKit
        self.rateService = rateService
        self.nftMetadataService = nftMetadataService

        subscribe(disposeBag, adapter.transactionsObservable(token: nil, filter: .all)) { [weak self] in self?.sync(transactionRecords: $0) }
        subscribe(disposeBag, adapter.lastBlockUpdatedObservable) { [weak self] in self?.syncItem() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
        subscribe(disposeBag, nftMetadataService.assetsBriefMetadataObservable) { [weak self] in self?.handle(assetsBriefMetadata: $0) }

        fetchRates()
        fetchNftMetadata()
    }

    private var tokenForRates: [Token] {
        var tokens = [Token?]()

        switch transactionRecord {
        case let tx as EvmIncomingTransactionRecord: tokens.append(tx.value.token)
        case let tx as EvmOutgoingTransactionRecord: tokens.append(tx.value.token)
        case let tx as SwapTransactionRecord:
            tokens.append(tx.valueIn.token)
            tx.valueOut.flatMap { tokens.append($0.token) }

        case let tx as UnknownSwapTransactionRecord:
            tx.valueIn.flatMap { tokens.append($0.token) }
            tx.valueOut.flatMap { tokens.append($0.token) }

        case let tx as ApproveTransactionRecord: tokens.append(tx.value.token)
        case let tx as ContractCallTransactionRecord:
            tokens.append(contentsOf: tx.incomingEvents.map({ $0.value.token }))
            tokens.append(contentsOf: tx.outgoingEvents.map({ $0.value.token }))

        case let tx as ExternalContractCallTransactionRecord:
            tokens.append(contentsOf: tx.incomingEvents.map({ $0.value.token }))
            tokens.append(contentsOf: tx.outgoingEvents.map({ $0.value.token }))

        case let tx as BitcoinIncomingTransactionRecord: tokens.append(tx.value.token)
        case let tx as BitcoinOutgoingTransactionRecord:
            tx.fee.flatMap { tokens.append($0.token) }
            tokens.append(tx.value.token)

        case let tx as BinanceChainIncomingTransactionRecord: tokens.append(tx.value.token)
        case let tx as BinanceChainOutgoingTransactionRecord:
            tokens.append(tx.fee.token)
            tokens.append(tx.value.token)

        default: ()
        }

        if let evmTransaction = transactionRecord as? EvmTransactionRecord, evmTransaction.ownTransaction, let fee = evmTransaction.fee {
            tokens.append(fee.token)
        }

        return Array(Set(tokens.compactMap({ $0 })))
    }

    private func fetchRates() {
        tokenForRates.forEach { token in
            let rateKey = RateKey(token: token, date: transactionRecord.date)
            if let currencyValue = rateService.rate(key: rateKey) {
                rates[rateKey] = currencyValue
            } else {
                rateService.fetchRate(key: rateKey)
            }
        }

        syncItem()
    }

    private func fetchNftMetadata() {
        let nftUids = transactionRecord.nftUids
        let assetsBriefMetadata = nftMetadataService.assetsBriefMetadata(nftUids: nftUids)

        nftMetadata = assetsBriefMetadata

        if !nftUids.subtracting(Set(assetsBriefMetadata.keys)).isEmpty {
            nftMetadataService.fetch(nftUids: nftUids)
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        rates[rate.0] = rate.1
        syncItem()
    }

    private func handle(assetsBriefMetadata: [NftUid: NftAssetBriefMetadata]) {
        nftMetadata = assetsBriefMetadata
        syncItem()
    }

    private func sync(transactionRecords: [TransactionRecord]) {
        guard let transactionRecord = transactionRecords.first(where: { self.transactionRecord == $0 }) else {
            return
        }

        self.transactionRecord = transactionRecord
        transactionInfoItemSubject.onNext(item)
    }

    private func syncItem() {
        transactionInfoItemSubject.onNext(item)
    }

}

extension TransactionInfoService {

    var item: Item {
        Item(
                record: transactionRecord,
                lastBlockInfo: adapter.lastBlockInfo,
                rates: Dictionary(uniqueKeysWithValues: rates.map { key, value in (key.token.coin, value) }),
                nftMetadata: nftMetadata,
                explorerTitle: adapter.explorerTitle,
                explorerUrl: adapter.explorerUrl(transactionHash: transactionRecord.transactionHash)
        )
    }

    var transactionItemUpdatedObserver: Observable<Item> {
        transactionInfoItemSubject.asObservable()
    }

    func rawTransaction() -> String? {
        adapter.rawTransaction(hash: transactionRecord.transactionHash)
    }

}

extension TransactionInfoService {

    struct Item {
        let record: TransactionRecord
        let lastBlockInfo: LastBlockInfo?
        let rates: [Coin: CurrencyValue]
        let nftMetadata: [NftUid: NftAssetBriefMetadata]
        let explorerTitle: String
        let explorerUrl: String?
    }

}
