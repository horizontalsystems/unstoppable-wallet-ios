import Foundation
import RealmSwift

class HeaderHandler {
    static let shared = HeaderHandler()

    enum HandleError: Error {
        case emptyHeaders
        case noInitialBlock
    }

    let realmFactory: RealmFactory
    let creator: BlockCreator
    let validator: BlockValidator
    let saver: BlockSaver

    init(realmFactory: RealmFactory = .shared, creator: BlockCreator = .shared, validator: BlockValidator = TestNetBlockValidator(), saver: BlockSaver = .shared) {
        self.realmFactory = realmFactory
        self.creator = creator
        self.validator = validator
        self.saver = saver
    }

    func handle(headers: [BlockHeader]) throws {
        guard !headers.isEmpty else {
            throw HandleError.emptyHeaders
        }

        let realm = realmFactory.realm

        guard let initialBlock = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height").last else {
            throw HandleError.noInitialBlock
        }

        let newBlocks = creator.create(fromHeaders: headers, initialBlock: initialBlock)
        var validBlocks = [Block]()

        var validationError: Error?

        do {
            for newBlock in newBlocks {
                try validator.validate(block: newBlock)
                validBlocks.append(newBlock)
            }
        } catch {
            validationError = error
        }

        if !validBlocks.isEmpty {
            try saver.create(blocks: validBlocks)
        }

        if let validationError = validationError {
            throw validationError
        }
    }

}
