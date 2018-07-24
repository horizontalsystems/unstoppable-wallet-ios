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

    init(realmFactory: RealmFactory = .shared, validator: MerkleBlockValidator = MerkleBlockValidator(), saver: BlockSaver = .shared) {
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

        try validator.validate(message: message)

        saver.update(block: block, withTransactionHashes: validator.txIds)
    }

}
