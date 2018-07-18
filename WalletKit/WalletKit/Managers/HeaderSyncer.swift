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

//    func handle(blockHeaders: [BlockHeaderItem]) {
//        guard let firstBlock = blockHeaders.first else {
//            print("Headers Syncer: empty block headers")
//            return
//        }
//
//        guard let realm = realmFactory?.realm else {
//            return
//        }
//
//        var currentHeight = 0
//        let predicate = NSPredicate(format: "headerHash = %@", Data(firstBlock.prevBlock.reversed()).hex)
//
//        if let previousBlock = realm.objects(Block.self).filter(predicate).first {
//            print("Headers Syncer: previous block exists. Height is: \(previousBlock.height)")
//            currentHeight = previousBlock.height
//        } else if let checkpoint = network.checkpoints.first(where: { $0.hash == firstBlock.prevBlock }) {
//            print("Headers Syncer: checkpoint found at height: \(checkpoint.height)")
//            currentHeight = Int(checkpoint.height)
//        } else {
//            print("Headers Syncer: no previous block found")
//            return
//        }
//
//        var blocks = [Block]()
//
//        for blockHeader in blockHeaders {
//            currentHeight += 1
//
//            let hash = Crypto.sha256sha256(blockHeader.serialized())
//
//            let block = Block()
//            block.headerHash = Data(hash.reversed()).hex
//            block.height = currentHeight
//
//            blocks.append(block)
//        }
//
//        try? realm.write {
//            realm.add(blocks, update: true)
//        }
//
////        if blockHeaders.count == 2000 {
////            sync()
////        }
//    }
