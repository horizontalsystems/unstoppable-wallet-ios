import Foundation

class BlockSaver {
    static let shared = BlockSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func create(withHeight height: Int, fromItems items: [BlockHeaderItem]) {
        let realm = realmFactory.realm

        var currentHeight = height
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

    func update(block: Block, withTransactionHashes hashes: [Data]) {
        let realm = realmFactory.realm

        var transactions = [Transaction]()

        for hash in hashes {
            let transaction = Transaction()
            transaction.transactionHash = hash.reversedHex
            transaction.block = block
            transactions.append(transaction)
        }

        try? realm.write {
            realm.add(transactions, update: true)
            block.synced = true
        }
    }

}
