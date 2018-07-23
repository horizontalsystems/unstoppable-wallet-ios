import Foundation
import RealmSwift

class BlockSyncer {
    static let shared = BlockSyncer()

    let realmFactory: RealmFactory
    let peerManager: PeerManager

    init(realmFactory: RealmFactory = .shared, peerManager: PeerManager = .shared) {
        self.realmFactory = realmFactory
        self.peerManager = peerManager
    }

    func sync() {
        let realm = realmFactory.realm

        let nonSyncedBlocks = realm.objects(Block.self).filter("synced = %@", false).sorted(byKeyPath: "height")
        let hashes = nonSyncedBlocks.map { $0.headerHash }

        if !hashes.isEmpty {
            peerManager.requestBlocks(headerHashes: Array(hashes))
        }
    }

}
