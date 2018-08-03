import Foundation
import RealmSwift

class HeaderHandler {
    static let shared = HeaderHandler()

    enum HandleError: Error {
        case emptyHeaders
        case noInitialBlock
    }

    let storage: IStorage
    let blockFactory: BlockFactory
    let validator: BlockValidator
    let saver: BlockSaver

    init(storage: IStorage = RealmStorage.shared, blockFactory: BlockFactory = .shared, validator: BlockValidator = TestNetBlockValidator(), saver: BlockSaver = .shared) {
        self.storage = storage
        self.blockFactory = blockFactory
        self.validator = validator
        self.saver = saver
    }

    func handle(headers: [BlockHeader]) throws {
        guard !headers.isEmpty else {
            throw HandleError.emptyHeaders
        }

        guard let initialBlock = storage.getLastBlockInChain() else {
            throw HandleError.noInitialBlock
        }

        let newBlocks = blockFactory.blocks(fromHeaders: headers, initialBlock: initialBlock)
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
