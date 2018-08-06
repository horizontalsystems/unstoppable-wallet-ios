import Foundation
import RealmSwift
import RxSwift

class BlockSyncer {
    static let shared = BlockSyncer()
    let disposeBag = DisposeBag()

    let realmFactory: RealmFactory
    let peerGroup: PeerGroup

    private var notificationToken: NotificationToken?

    init(realmFactory: RealmFactory = .shared, peerGroup: PeerGroup = .shared, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background), queue: DispatchQueue = .global(qos: .background)) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup

        peerGroup.statusSubject
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] status in
                    if status == .connected {
                        self?.sync()
                    }
                }).disposed(by: disposeBag)

        notificationToken = realmFactory.realm.objects(Block.self).filter("synced = %@", false).observe { changes in
            queue.async { [weak self] in
                if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                    self?.sync()
                }
            }
        }
    }

    private func sync() {
        let realm = realmFactory.realm

        let nonSyncedBlocks = realm.objects(Block.self).filter("synced = %@", false).sorted(byKeyPath: "height")
        let hashes = nonSyncedBlocks.map { $0.headerHash }

        if !hashes.isEmpty {
            peerGroup.requestBlocks(headerHashes: Array(hashes))
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

}
