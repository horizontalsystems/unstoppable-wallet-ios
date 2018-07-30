import Foundation
import RealmSwift
import RxSwift

class BlockSyncer {
    static let shared = BlockSyncer()
    let disposeBag = DisposeBag()

    let realmFactory: RealmFactory
    let peerManager: PeerManager

    private var notificationToken: NotificationToken?

    init(realmFactory: RealmFactory = .shared, peerManager: PeerManager = .shared) {
        self.realmFactory = realmFactory
        self.peerManager = peerManager

        peerManager.statusSubject.subscribe(onNext: { [weak self] status in
            if status == .connected {
                self?.sync()
            }
        }).disposed(by: disposeBag)

        notificationToken = realmFactory.realm.objects(Block.self).filter("synced = %@", false).observe { [weak self] changes in
            if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                self?.sync()
            }
        }
    }

    private func sync() {
        let realm = realmFactory.realm

        let nonSyncedBlocks = realm.objects(Block.self).filter("synced = %@", false).sorted(byKeyPath: "height")
        let hashes = nonSyncedBlocks.map { $0.headerHash }

        if !hashes.isEmpty {
            peerManager.requestBlocks(headerHashes: Array(hashes))
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

}
