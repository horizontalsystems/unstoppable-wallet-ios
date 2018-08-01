import Foundation
import RealmSwift

class HeaderSyncer {
    static let shared = HeaderSyncer()

    enum SyncError: Error {
        case noCheckpointBlock
    }

    private let hashCheckpointThreshold = 100

    let realmFactory: RealmFactory
    let peerGroup: PeerGroup

    init(realmFactory: RealmFactory = .shared, peerGroup: PeerGroup = .shared) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup
    }

    func sync() throws {
        let realm = realmFactory.realm

        guard let checkpointBlock = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height").first else {
            throw SyncError.noCheckpointBlock
        }

        var hashes = [Data]()

        if let lastBlockInDatabase = realm.objects(Block.self).filter("previousBlock != nil AND height > %@", checkpointBlock.height).sorted(byKeyPath: "height").last {
            hashes.append(lastBlockInDatabase.headerHash)

            if lastBlockInDatabase.height - checkpointBlock.height >= hashCheckpointThreshold,
               let previousBlock = realm.objects(Block.self).filter("previousBlock != nil AND height = %@", lastBlockInDatabase.height - hashCheckpointThreshold + 1).first {
                hashes.append(previousBlock.headerHash)
            }
        }

        if hashes.count < 2 {
            hashes.append(checkpointBlock.headerHash)
        }

        peerGroup.requestHeaders(headerHashes: hashes)
    }

}
