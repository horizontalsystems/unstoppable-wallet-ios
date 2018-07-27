import Foundation
import RealmSwift

class HeaderHandler {
    static let shared = HeaderHandler()

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
            print("HeaderHandler: Empty block headers")
            return
        }

        let realm = realmFactory.realm

        guard let lastBlock = realm.objects(Block.self).filter("previousBlock != nil").sorted(byKeyPath: "height").last else {
            print("HeaderHandler: No last block")
            return
        }

        let newBlocks = creator.create(fromHeaders: headers, initialBlock: lastBlock)
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
