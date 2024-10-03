import Combine
import Foundation
import MarketKit
import RxSwift

class TransactionInfoViewModelNew: ObservableObject {
    private(set) var record: TransactionRecord
    private let adapter: ITransactionsAdapter

    private let balanceHiddenManager = App.shared.balanceHiddenManager
    private let rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
    private let nftMetadataService = NftMetadataService(nftMetadataManager: App.shared.nftMetadataManager)
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    private var rates = [RateKey: CurrencyValue]()
    private var nftMetadata = [NftUid: NftAssetBriefMetadata]()

    @Published var sections = [TransactionRecord.Section]()

    init(record: TransactionRecord, adapter: ITransactionsAdapter) {
        self.record = record
        self.adapter = adapter

        rateService.rateUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(rate: $0) }
            .store(in: &cancellables)

        adapter.transactionsObservable(token: nil, filter: .all, address: nil)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in self?.sync(records: $0) })
            .disposed(by: disposeBag)

        adapter.lastBlockUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in self?.syncSections() })
            .disposed(by: disposeBag)

        nftMetadataService.assetsBriefMetadataObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in
                self?.nftMetadata = $0
                self?.syncSections()
            })
            .disposed(by: disposeBag)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] _ in self?.syncSections() })
            .disposed(by: disposeBag)

        fetchRates()
        fetchNftMetadata()
    }

    private func syncSections() {
        sections = record.sections(
            lastBlockInfo: adapter.lastBlockInfo,
            rates: Dictionary(uniqueKeysWithValues: rates.map { key, value in (key.token.coin, value) }),
            nftMetadata: nftMetadata,
            explorerTitle: adapter.explorerTitle,
            explorerUrl: adapter.explorerUrl(transactionHash: record.transactionHash),
            hidden: balanceHiddenManager.balanceHidden
        )
    }

    private func sync(records: [TransactionRecord]) {
        guard let record = records.first(where: { record == $0 }) else {
            return
        }

        self.record = record
        syncSections()
    }

    private func fetchRates() {
        for token in Array(Set(record.rateTokens.compactMap { $0 })) {
            let rateKey = RateKey(token: token, date: record.date)
            if let currencyValue = rateService.rate(key: rateKey) {
                rates[rateKey] = currencyValue
            } else {
                rateService.fetchRate(key: rateKey)
            }
        }

        syncSections()
    }

    private func fetchNftMetadata() {
        let nftUids = record.nftUids
        let assetsBriefMetadata = nftMetadataService.assetsBriefMetadata(nftUids: nftUids)

        nftMetadata = assetsBriefMetadata

        if !nftUids.subtracting(Set(assetsBriefMetadata.keys)).isEmpty {
            nftMetadataService.fetch(nftUids: nftUids)
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        rates[rate.0] = rate.1
        syncSections()
    }
}

extension TransactionInfoViewModelNew {
    func rawTransaction() -> String? {
        adapter.rawTransaction(hash: record.transactionHash)
    }
}

extension TransactionInfoViewModelNew {
    enum Option {
        case resend(type: ResendTransactionType)
    }
}
