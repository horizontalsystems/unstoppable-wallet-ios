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

    func handle(blockHeaders: [BlockHeaderItem]) throws {
        guard !blockHeaders.isEmpty else {
            print("HeaderHandler: Empty block headers")
            return
        }

        let realm = realmFactory.realm

        guard let lastBlock = realm.objects(Block.self).filter("archived = %@", false).sorted(byKeyPath: "height").last else {
            print("HeaderHandler: No last block")
            return
        }

        var validHeaders = [BlockHeaderItem]()

        let initialHeaderItem = BlockHeaderItem.deserialize(byteStream: ByteStream(lastBlock.rawHeader))

        defer {
            if !validHeaders.isEmpty {
                saver.create(withHeight: lastBlock.height, fromItems: validHeaders)
            }
        }

        for (index, headerItem) in blockHeaders.enumerated() {
            try validator.validate(item: headerItem, previousItem: validHeaders.last ?? initialHeaderItem, previousHeight: lastBlock.height + index)
            validHeaders.append(headerItem)
        }
    }

}
