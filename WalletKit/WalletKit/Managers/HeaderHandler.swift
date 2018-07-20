import Foundation
import RealmSwift

class HeaderHandler {
    static let shared = HeaderHandler()

    let realmFactory: RealmFactory
    let validator: BlockHeaderItemValidator
    let saver: BlockSaver

    init(realmFactory: RealmFactory = .shared, validator: BlockHeaderItemValidator = .shared, saver: BlockSaver = .shared) {
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

        var validHeaders = [BlockHeaderItem]()

        let initialHeaderItem = BlockHeaderItem.deserialize(byteStream: ByteStream(lastBlock.rawHeader))
        for headerItem in blockHeaders {
            if validator.isValid(item: headerItem, previousBlock: validHeaders.last ?? initialHeaderItem) {
                validHeaders.append(headerItem)
            } else {
                break
            }
        }

        if !validHeaders.isEmpty {
            saver.create(withHeight: lastBlock.height, fromItems: validHeaders)
        }
    }

}
