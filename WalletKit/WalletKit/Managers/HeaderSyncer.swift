import Foundation
import RealmSwift

class HeaderSyncer {
    static let shared = HeaderSyncer()

    enum SyncError: Error {
        case noCheckpointBlock
    }

    private let hashCheckpointThreshold = 100

    let realmFactory: RealmFactory
    let peerManager: PeerManager

    init(realmFactory: RealmFactory = .shared, peerManager: PeerManager = .shared) {
        self.realmFactory = realmFactory
        self.peerManager = peerManager
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

        peerManager.requestHeaders(headerHashes: hashes)
    }

}
