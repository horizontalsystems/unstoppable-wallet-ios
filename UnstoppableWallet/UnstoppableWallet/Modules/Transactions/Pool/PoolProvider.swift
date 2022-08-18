import Foundation
import RxSwift
import RxRelay
import MarketKit

class PoolProvider {
    private let adapter: ITransactionsAdapter
    private let source: PoolSource
    private let disposeBag = DisposeBag()

    private let syncingRelay = PublishRelay<Bool>()
    private(set) var syncing = false {
        didSet {
            if oldValue != syncing {
                syncingRelay.accept(syncing)
            }
        }
    }

    init(adapter: ITransactionsAdapter, source: PoolSource) {
        self.adapter = adapter
        self.source = source

        adapter.syncingObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] in
                    self?.syncing = adapter.syncing
                })
                .disposed(by: disposeBag)

        syncing = adapter.syncing
    }

}

extension PoolProvider {

    var syncingObservable: Observable<Bool> {
        syncingRelay.asObservable()
    }

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    func recordsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        adapter.transactionsSingle(from: from, token: source.configuredToken?.token, filter: source.filter, limit: limit)
    }

    func recordsObservable() -> Observable<[TransactionRecord]> {
        adapter.transactionsObservable(token: source.configuredToken?.token, filter: source.filter)
    }

    func lastBlockUpdatedObservable() -> Observable<Void> {
        adapter.lastBlockUpdatedObservable
    }

}
