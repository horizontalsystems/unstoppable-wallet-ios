import Foundation
import RealmSwift
import RxSwift

class BlockSyncer: BackgroundWorker {
    let disposeBag = DisposeBag()

    let realmFactory: RealmFactory
    let peerGroup: PeerGroup

    private var notificationToken: NotificationToken?

    init(realmFactory: RealmFactory, peerGroup: PeerGroup, sync: Bool = false, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup

        super.init(sync: sync)

        peerGroup.statusSubject
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] status in
                    if status == .connected {
                        self?.sync()
                    }
                }).disposed(by: disposeBag)

        start { [weak self] in
            self?.notificationToken = self?.realmFactory.realm.objects(Block.self).filter("synced = %@", false).observe { changes in
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
