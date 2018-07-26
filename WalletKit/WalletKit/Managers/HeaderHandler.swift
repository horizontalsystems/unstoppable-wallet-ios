import Foundation
import RealmSwift

class HeaderHandler {
    static let shared = HeaderHandler()

    let realmFactory: RealmFactory
    let validator: BlockHeaderItemValidator
    let saver: BlockSaver

    init(realmFactory: RealmFactory = .shared, validator: BlockHeaderItemValidator = BlockHeaderItemValidator(), saver: BlockSaver = .shared) {
        self.realmFactory = realmFactory
        self.validator = validator
        self.saver = saver
    }

    func handle(headers: [BlockHeader]) throws {
        guard !headers.isEmpty else {
            print("HeaderHandler: Empty block headers")
            return
        }

        let realm = realmFactory.realm

        guard let lastBlock = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height").last else {
            print("HeaderHandler: No last block")
            return
        }

        var newBlocks = [Block]()
        var previousBlock = lastBlock

        for header in headers {
            let newBlock = Block(header: header, previousBlock: previousBlock)
            newBlocks.append(newBlock)

            previousBlock = newBlock
        }

        var validBlocks = [Block]()

        defer {
            if !validBlocks.isEmpty {
                saver.create(blocks: validBlocks)
            }
        }

        for newBlock in newBlocks {
            try validator.validate(block: newBlock)
            validBlocks.append(newBlock)
        }
    }

}
