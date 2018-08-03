import Foundation
import RealmSwift
import RxSwift

class BlockSyncer {
    static let shared = BlockSyncer()
    let disposeBag = DisposeBag()

    let storage: IStorage
    let peerGroup: PeerGroup

    init(storage: IStorage = RealmStorage.shared, peerGroup: PeerGroup = .shared, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.storage = storage
        self.peerGroup = peerGroup

        peerGroup.statusSubject
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] status in
                    if status == .connected {
                        self?.sync()
                    }
                }).disposed(by: disposeBag)

        storage.nonSyncedBlocksInsertSubject
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                }).disposed(by: disposeBag)
    }

    private func sync() {
        let hashes = storage.getNonSyncedBlockHeaderHashes()

        if !hashes.isEmpty {
            peerGroup.requestBlocks(headerHashes: Array(hashes))
        }
    }

}
