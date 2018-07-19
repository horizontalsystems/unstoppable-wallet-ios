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

            let rawHeader = item.serialized()
            let hash = Crypto.sha256sha256(rawHeader)

            let block = Block()
            block.reversedHeaderHashHex = hash.reversedHex
            block.headerHash = hash
            block.rawHeader = rawHeader
            block.height = currentHeight

            blocks.append(block)
        }

        try? realm.write {
            realm.add(blocks, update: true)
        }
    }

}
