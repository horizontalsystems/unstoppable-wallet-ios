import Foundation

class HeaderSyncer {
    static let shared = HeaderSyncer()

    enum SyncError: Error {
        case noCheckpointBlock
    }

    private let hashCheckpointThreshold = 100

    let storage: IStorage
    let peerGroup: PeerGroup

    init(storage: IStorage = RealmStorage.shared, peerGroup: PeerGroup = .shared) {
        self.storage = storage
        self.peerGroup = peerGroup
    }

    func sync() throws {
        guard let checkpointBlock = storage.getFirstBlockInChain() else {
            throw SyncError.noCheckpointBlock
        }

        var hashes = [Data]()

        if let lastBlockInDatabase = storage.getLastBlockInChain(afterBlock: checkpointBlock) {
            hashes.append(lastBlockInDatabase.headerHash)

            if lastBlockInDatabase.height - checkpointBlock.height >= hashCheckpointThreshold, let previousBlock = storage.getBlockInChain(withHeight: lastBlockInDatabase.height - hashCheckpointThreshold + 1) {
                hashes.append(previousBlock.headerHash)
            }
        }

        if hashes.count < 2 {
            hashes.append(checkpointBlock.headerHash)
        }

        peerGroup.requestHeaders(headerHashes: hashes)
    }

}
