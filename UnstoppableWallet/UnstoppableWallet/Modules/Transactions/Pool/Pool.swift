import Foundation
import RxSwift
import RxRelay

class Pool {
    private let provider: NonSpamPoolProvider
    private let disposeBag = DisposeBag()

    private let invalidatedRelay = PublishRelay<()>()
    private let itemsUpdatedRelay = PublishRelay<[TransactionItem]>()

    private(set) var items = [TransactionItem]()
    private var invalidated = false
    private var allLoaded = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.pool")

    init(provider: NonSpamPoolProvider) {
        self.provider = provider

        provider.recordsObservable()
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] records in
                    self?.handleUpdated(records: records)
                })
                .disposed(by: disposeBag)

        provider.lastBlockUpdatedObservable()
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] in
                    self?.handleUpdatedLastBlock()
                })
                .disposed(by: disposeBag)
    }

    private func handleUpdated(records: [TransactionRecord]) {
        queue.async {
            guard !records.isEmpty else {
                return
            }

            var updatesOnly = true
            var updatedItems = [TransactionItem]()

            for record in records {
                guard let index = self.items.firstIndex(where: { $0.record == record }) else {
                    updatesOnly = false
                    break
                }

                self.items[index].record = record
                updatedItems.append(self.items[index])
            }

            if updatesOnly {
                self.itemsUpdatedRelay.accept(updatedItems)
                return
            }

            guard let mostRecentRecord = records.min() else {
                return
            }

            if let lastRecord = self.items.last?.record, mostRecentRecord > lastRecord {
                return
            }

            self.invalidated = true
            self.invalidatedRelay.accept(())
        }
    }

    private func handleUpdatedLastBlock() {
        queue.async {
            let lastBlockInfo = self.provider.lastBlockInfo

//            print("Handle updated last block: \(lastBlockInfo?.height ?? -1)")

            var updatedItems = [TransactionItem]()

            for index in 0..<self.items.count {
                let item = self.items[index]
                var changed = false

                if item.status.isPendingOrProcessing {
                    let newStatus = item.record.status(lastBlockHeight: lastBlockInfo?.height)
                    if item.status != newStatus {
                        self.items[index].status = newStatus
                        changed = true
                    }
                }

                if let lockState = item.lockState, lockState.locked, let newLockState = item.record.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp), !newLockState.locked {
                    self.items[index].lockState = newLockState
                    changed = true
                }


                if changed {
                    updatedItems.append(self.items[index])
                }
            }

            if !updatedItems.isEmpty {
                self.itemsUpdatedRelay.accept(updatedItems)
            }
        }
    }

    private func handleFetched(items: [TransactionItem], requestedCount: Int) {
        queue.async {
            self.items = items

            self.allLoaded = items.count < requestedCount
        }
    }

    private func transactionItems(records: [TransactionRecord]) -> [TransactionItem] {
        let lastBlockInfo = provider.lastBlockInfo

        return records.map { record in
            TransactionItem(
                    record: record,
                    status: record.status(lastBlockHeight: lastBlockInfo?.height),
                    lockState: record.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)
            )
        }
    }

}

extension Pool {

    var invalidatedObservable: Observable<()> {
        invalidatedRelay.asObservable()
    }

    var itemsUpdatedObservable: Observable<[TransactionItem]> {
        itemsUpdatedRelay.asObservable()
    }

    var syncing: Bool {
        provider.syncing
    }

    var syncingObservable: Observable<Bool> {
        provider.syncingObservable
    }

    func itemsSingle(count: Int) -> Single<[TransactionItem]> {
        queue.sync {
//            print("Pool: single for \(count)\(invalidated ? " (INVALIDATED)" : "")")

            if invalidated {
                invalidated = false

                return provider.recordsSingle(from: nil, limit: count)
                        .map { [weak self] records in
                            self?.transactionItems(records: records) ?? []
                        }
                        .do(onSuccess: { [weak self] items in
                            self?.handleFetched(items: items, requestedCount: count)
                        })
            } else if allLoaded {
                return Single.just(items)
            } else {
                let items = items

                if items.count >= count {
                    return Single.just(items)
                }

                let requiredCount = count - items.count
                let lastItem = items.last

                return provider.recordsSingle(from: lastItem?.record, limit: requiredCount)
                        .map { [weak self] records in
                            self?.transactionItems(records: records) ?? []
                        }
                        .map {
                            items + $0
                        }
                        .do(onSuccess: { [weak self] items in
                            self?.handleFetched(items: items, requestedCount: count)
                        })
            }
        }
    }

}
