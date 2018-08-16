import Foundation

class TransactionHandler {
    enum HandleError: Error {
        case transactionNotFound
        case blockNotFound
    }

    let realmFactory: RealmFactory
    let worker: TransactionWorker

    init(realmFactory: RealmFactory, worker: TransactionWorker) {
        self.realmFactory = realmFactory
        self.worker = worker
    }

    func handle(blockHeaderHash: Data, transactions: [Transaction]) throws {
        let realm = realmFactory.realm

        guard let block = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", blockHeaderHash.reversedHex).last else {
            throw HandleError.blockNotFound
        }

        try realm.write {
            block.synced = true
            realm.add(transactions, update: true)
        }

        print("HANDLE: \(transactions.count) --- \(Thread.current)")
        if !transactions.isEmpty {
            worker.handle(transactionHexes: transactions.map { $0.reversedHashHex })
        }
    }

    func handle(transaction: Transaction) throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.add(transaction, update: true)
        }
    }
}
