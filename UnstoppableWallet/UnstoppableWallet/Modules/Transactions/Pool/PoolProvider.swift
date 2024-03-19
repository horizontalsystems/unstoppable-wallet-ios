import Foundation
import MarketKit
import RxRelay
import RxSwift

protocol IPoolProvider {
    var syncing: Bool { get }
    var syncingObservable: Observable<Bool> { get }
    var lastBlockInfo: LastBlockInfo? { get }
    func recordsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]>
    func recordsObservable() -> Observable<[TransactionRecord]>
    func lastBlockUpdatedObservable() -> Observable<Void>
}

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
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in
                self?.syncing = adapter.syncing
            })
            .disposed(by: disposeBag)

        syncing = adapter.syncing
    }
}

extension PoolProvider: IPoolProvider {
    var syncingObservable: Observable<Bool> {
        syncingRelay.asObservable()
    }

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    func recordsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]> {
        adapter.transactionsSingle(from: from, token: source.token, filter: source.filter, address: source.address, limit: limit)
    }

    func recordsObservable() -> Observable<[TransactionRecord]> {
        adapter.transactionsObservable(token: source.token, filter: source.filter, address: source.address)
    }

    func lastBlockUpdatedObservable() -> Observable<Void> {
        adapter.lastBlockUpdatedObservable
    }
}
