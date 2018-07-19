import Foundation

class BlockHeaderItemSaver {
    static let shared = BlockHeaderItemSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func save(lastHeight: Int, items: [BlockHeaderItem]) {
        let realm = realmFactory.realm

        var currentHeight = lastHeight
        var blocks = [Block]()

        for item in items {
            currentHeight += 1

            let hash = Crypto.sha256sha256(item.serialized())

            let block = Block()
            block.reversedHeaderHashHex = hash.reversedHex
            block.height = currentHeight

            blocks.append(block)
        }

        try? realm.write {
            realm.add(blocks, update: true)
        }
    }

}
