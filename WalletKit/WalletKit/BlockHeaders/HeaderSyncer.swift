import Foundation
import RealmSwift

class HeaderSyncer {
    let realmFactory: RealmFactory
    let peerGroup: PeerGroup
    let network: NetworkProtocol
    let hashCheckpointThreshold: Int

    init(realmFactory: RealmFactory, peerGroup: PeerGroup, network: NetworkProtocol, hashCheckpointThreshold: Int = 100) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup
        self.network = network
        self.hashCheckpointThreshold = hashCheckpointThreshold
    }

    func sync() throws {
        let realm = realmFactory.realm

        let blocksInChain = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height")

        var blocks = [Block]()

        if let lastBlockInDatabase = blocksInChain.last {
            blocks.append(lastBlockInDatabase)

            if let thresholdBlock = blocksInChain.filter("height = %@", lastBlockInDatabase.height - hashCheckpointThreshold).first {
                blocks.append(thresholdBlock)
            } else if let firstBlock = blocksInChain.filter("height <= %@", lastBlockInDatabase.height).first, let checkpointBlock = firstBlock.previousBlock {
                blocks.append(checkpointBlock)
            }
        } else {
            blocks.append(network.checkpointBlock)
        }

        peerGroup.requestHeaders(headerHashes: blocks.map { $0.headerHash })
    }

}
