import Foundation
import RealmSwift
import RxSwift

class BlockSyncer {
    let realmFactory: RealmFactory
    let peerGroup: PeerGroup
    private let queue: DispatchQueue

    init(realmFactory: RealmFactory, peerGroup: PeerGroup, queue: DispatchQueue = DispatchQueue(label: "BlockSyncer", qos: .background)) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup
        self.queue = queue
    }

    func enqueueRun() {
        queue.async {
            self.run()
        }
    }

    private func run() {
        let realm = realmFactory.realm

        let nonSyncedBlocks = realm.objects(Block.self).filter("synced = %@", false)
        let hashes = nonSyncedBlocks.map { $0.headerHash }

        if !hashes.isEmpty {
            peerGroup.requestBlocks(headerHashes: Array(hashes))
        }
    }

}
