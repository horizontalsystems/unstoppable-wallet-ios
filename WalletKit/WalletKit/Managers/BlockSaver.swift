import Foundation

class BlockSaver {
    static let shared = BlockSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func create(blocks: [Block]) throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.add(blocks, update: true)
        }
    }

    func update(block: Block, withTransactionHashes hashes: [Data]) throws {
        let realm = realmFactory.realm

        var transactions = [Transaction]()

        for hash in hashes {
            let transaction = Transaction()
            transaction.reversedHashHex = hash.reversedHex
            transaction.block = block
            transactions.append(transaction)
        }

        try realm.write {
            realm.add(transactions, update: true)
            block.synced = true
        }
    }

}
