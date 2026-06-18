import Foundation
import RxRelay
import RxSwift

public class PoolGroup {
    private let pools: [Pool]
    private let disposeBag = DisposeBag()

    private let syncingRelay = PublishRelay<Bool>()
    public private(set) var syncing = false {
        didSet {
            if oldValue != syncing {
                syncingRelay.accept(syncing)
            }
        }
    }

    public init(pools: [Pool]) {
        self.pools = pools

        Observable.merge(pools.map(\.syncingObservable))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] _ in
                self?.syncState()
            })
            .disposed(by: disposeBag)

        syncState()
    }

    private func syncState() {
        for pool in pools {
            if pool.syncing {
                syncing = true
                return
            }
        }

        syncing = false
    }
}

public extension PoolGroup {
    var syncingObservable: Observable<Bool> {
        syncingRelay.asObservable()
    }

    var invalidatedObservable: Observable<Void> {
        Observable.merge(pools.map(\.invalidatedObservable))
    }

    var itemsUpdatedObservable: Observable<[TransactionItem]> {
        Observable.merge(pools.map(\.itemsUpdatedObservable))
    }

    func itemsSingle(count: Int) -> Single<[TransactionItem]> {
        let singles = pools.map { pool in
            pool.itemsSingle(count: count)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        }

        return Single.zip(singles)
            .map { itemsArray in
                let allItems = itemsArray.flatMap { $0 }
                return Array(allItems.sorted().prefix(count))
            }
    }
}
