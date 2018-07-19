import Foundation
import RealmSwift

class HeaderSyncer {
    static let shared = HeaderSyncer()

    private let hashCheckpointThreshold = 100

    let realmFactory: RealmFactory
    let peerManager: PeerManager

    init(realmFactory: RealmFactory = .shared, peerManager: PeerManager = .shared) {
        self.realmFactory = realmFactory
        self.peerManager = peerManager
    }

    func sync() {
        let realm = realmFactory.realm

        guard let checkpointBlock = realm.objects(Block.self).filter("archived = %@", false).sorted(byKeyPath: "height").first else {
            print("HeaderSyncer: No checkpoint block found")
            return
        }

        var hashes = [Data]()

        if let lastBlockInDatabase = realm.objects(Block.self).filter("archived = %@ AND height > %@", false, checkpointBlock.height).sorted(byKeyPath: "height").last, let hash = lastBlockInDatabase.reversedHeaderHashHex.reversedData {
            hashes.append(hash)

            if lastBlockInDatabase.height - checkpointBlock.height >= hashCheckpointThreshold,
               let previousBlock = realm.objects(Block.self).filter("archived = %@ AND height = %@", false, lastBlockInDatabase.height - hashCheckpointThreshold + 1).first,
               let hash = previousBlock.reversedHeaderHashHex.reversedData {
                hashes.append(hash)
            }
        }

        if hashes.count < 2, let hash = checkpointBlock.reversedHeaderHashHex.reversedData {
            hashes.append(hash)
        }

        peerManager.requestHeaders(headerHashes: hashes)
    }

}
