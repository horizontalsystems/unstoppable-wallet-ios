import Foundation
import RxSwift
import RxRelay

class PoolGroup {
    private let pools: [Pool]
    private let disposeBag = DisposeBag()

    private let syncingRelay = PublishRelay<Bool>()
    private(set) var syncing = false {
        didSet {
            if oldValue != syncing {
                syncingRelay.accept(syncing)
            }
        }
    }

    init(pools: [Pool]) {
        self.pools = pools

        Observable.merge(pools.map { $0.syncingObservable })
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
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

extension PoolGroup {

    var syncingObservable: Observable<Bool> {
        syncingRelay.asObservable()
    }

    var invalidatedObservable: Observable<()> {
        Observable.merge(pools.map { $0.invalidatedObservable })
    }

    var itemsUpdatedObservable: Observable<[TransactionItem]> {
        Observable.merge(pools.map { $0.itemsUpdatedObservable })
    }

    func itemsSingle(count: Int) -> Single<[TransactionItem]> {
        let singles = pools.map { pool in
            pool.itemsSingle(count: count)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
        }

        return Single.zip(singles)
                .map { itemsArray in
                    let allItems = itemsArray.flatMap { $0 }
                    return Array(allItems.sorted().prefix(count))
                }
    }

}
