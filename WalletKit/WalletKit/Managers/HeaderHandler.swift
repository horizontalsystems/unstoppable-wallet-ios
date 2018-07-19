import Foundation
import RealmSwift

class HeaderHandler {
    static let shared = HeaderHandler()

    let realmFactory: RealmFactory
    let validator: BlockHeaderItemValidator
    let saver: BlockHeaderItemSaver

    init(realmFactory: RealmFactory = .shared, validator: BlockHeaderItemValidator = .shared, saver: BlockHeaderItemSaver = .shared) {
        self.realmFactory = realmFactory
        self.validator = validator
        self.saver = saver
    }

    func handle(blockHeaders: [BlockHeaderItem]) {
        guard !blockHeaders.isEmpty else {
            print("HeaderHandler: Empty block headers")
            return
        }

        let realm = realmFactory.realm

        guard let lastBlock = realm.objects(Block.self).filter("archived = %@", false).sorted(byKeyPath: "height").last else {
            print("HeaderHandler: No last block")
            return
        }

        guard let lastHash = lastBlock.reversedHeaderHashHex.reversedData else {
            print("HeaderHandler: Invalid last block hash")
            return
        }

        let validHeaders = validator.filterValidItems(initialHash: lastHash, items: blockHeaders)

        if !validHeaders.isEmpty {
            saver.save(lastHeight: lastBlock.height, items: validHeaders)
        }
    }

}
