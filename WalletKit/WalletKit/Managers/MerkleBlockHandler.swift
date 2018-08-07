import Foundation
import RealmSwift

class MerkleBlockHandler {
    static let shared = MerkleBlockHandler()

    enum HandleError: Error {
        case blockNotFound
    }

    let realmFactory: RealmFactory
    let validator: MerkleBlockValidator
    let saver: BlockSaver

    init(realmFactory: RealmFactory = .shared, validator: MerkleBlockValidator = .shared, saver: BlockSaver = .shared) {
        self.realmFactory = realmFactory
        self.validator = validator
        self.saver = saver
    }

    func handle(message: MerkleBlockMessage) throws {
        let realm = realmFactory.realm

        let headerHash = Crypto.sha256sha256(message.blockHeader.serialized())

        guard let block = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", headerHash.reversedHex).last else {
            throw HandleError.blockNotFound
        }

        let matchedTxIds = try validator.validateAndGetTxHashes(message: message)
        try saver.update(block: block, withTransactionHashes: matchedTxIds)
    }

}
