import Foundation
import RealmSwift

class MerkleBlockHandler {
    static let shared = MerkleBlockHandler()

    enum HandleError: Error {
        case blockNotFound
    }

    let storage: IStorage
    let validator: MerkleBlockValidator
    let saver: BlockSaver

    init(storage: IStorage = RealmStorage.shared, validator: MerkleBlockValidator = MerkleBlockValidator(), saver: BlockSaver = .shared) {
        self.storage = storage
        self.validator = validator
        self.saver = saver
    }

    func handle(message: MerkleBlockMessage) throws {
        let headerHash = Crypto.sha256sha256(message.blockHeader.serialized())

        guard let block = storage.getBlock(byHeaderHash: headerHash) else {
            throw HandleError.blockNotFound
        }

        try validator.validate(message: message)
        try saver.update(block: block, withTransactionHashes: validator.txIds)
    }

}
