import Foundation

class TransactionHandler {
    enum HandleError: Error {
        case invalidBlockHeader
    }

    let realmFactory: RealmFactory
    let processor: TransactionProcessor
    let headerHandler: HeaderHandler
    let factory: Factory

    init(realmFactory: RealmFactory, processor: TransactionProcessor, headerHandler: HeaderHandler, factory: Factory) {
        self.realmFactory = realmFactory
        self.processor = processor
        self.headerHandler = headerHandler
        self.factory = factory
    }

    func handle(blockTransactions transactions: [Transaction], blockHeader: BlockHeader) throws {
        let realm = realmFactory.realm
        let reversedHashHex = Crypto.sha256sha256(blockHeader.serialized()).reversedHex
        var _block = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", reversedHashHex).last

        if _block == nil {
            let validBlocks = headerHandler.getValidBlocks(headers: [blockHeader], realm: realm)

            if let validationError = validBlocks.error {
                throw validationError
            }

            _block = validBlocks.blocks.first
        } else {
            if _block?.previousBlock == nil {
                _block = factory.block(withHeader: blockHeader, height: 0)
            }
        }

        guard let block = _block else {
            throw HandleError.invalidBlockHeader
        }

        for transaction in transactions {
            transaction.block = block
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
