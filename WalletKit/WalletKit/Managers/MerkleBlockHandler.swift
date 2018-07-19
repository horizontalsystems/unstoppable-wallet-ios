import Foundation
import RealmSwift

class MerkleBlockHandler {
    enum HandleError: Error {
        case blockNotFound
    }

    static let shared = MerkleBlockHandler()

    let realmFactory: RealmFactory
    let validator: MerkleBlockValidator
    let saver: MerkleBlockSaver

    init(realmFactory: RealmFactory = .shared, validator: MerkleBlockValidator = .shared, saver: MerkleBlockSaver = .shared) {
        self.realmFactory = realmFactory
        self.validator = validator
        self.saver = saver
    }

    func handle(message: MerkleBlockMessage) throws {
        let realm = realmFactory.realm
        let reversedHeaderHashHex = Crypto.sha256sha256(message.blockHeaderItem.serialized())

        guard let block = realm.objects(Block.self)
                .filter("archived = %@ AND reversedHeaderHashHex = %@", false, reversedHeaderHashHex.reversedHex)
                .sorted(byKeyPath: "height").last else {
            throw HandleError.blockNotFound
        }

        if validator.isValid(message: message) {
            saver.save(block: block, message: message)
        }
    }

}
