import Foundation
import RealmSwift

class MerkleBlockHandler {
    enum HandleError: Error {
        case blockNotFound
    }

    static let shared = MerkleBlockHandler()

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
        let headerHash = Crypto.sha256sha256(message.blockHeaderItem.serialized())

        guard let block = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", headerHash.reversedHex).last else {
            throw HandleError.blockNotFound
        }

        if validator.isValid(message: message) {
            // Hash filtering logic must be hear. Only transaction hashes must be passed to saver.update
            let transactionHashes = message.hashes

            saver.update(block: block, withTransactionHashes: transactionHashes)
        }
    }

}
