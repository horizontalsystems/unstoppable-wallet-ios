import Foundation

class TransactionHandler {
    enum HandleError: Error {
        case transactionNotFound
        case blockNotFound
    }

    let realmFactory: RealmFactory
    let processor: TransactionProcessor

    init(realmFactory: RealmFactory, processor: TransactionProcessor) {
        self.realmFactory = realmFactory
        self.processor = processor
    }

    func handle(blockTransactions transactions: [Transaction], blockHeaderHash: Data) throws {
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
            processor.enqueueRun()
        }
    }

    func handle(memPoolTransactions transactions: [Transaction]) throws {
        guard !transactions.isEmpty else {
            return
        }

        let realm = realmFactory.realm

        try realm.write {
            realm.add(transactions, update: true)
        }

        processor.enqueueRun()
    }

}
