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

        var hasNewTransactions = false

        if let existingBlock = realm.objects(Block.self).filter("reversedHeaderHashHex = %@", reversedHashHex).last {
            if existingBlock.synced {
                return
            }

            try realm.write {
                if existingBlock.header == nil {
                    existingBlock.header = blockHeader
                }

                for transaction in transactions {
                    if let existingTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).first {
                        existingTransaction.block = existingBlock
                    } else {
                        realm.add(transaction)
                        transaction.block = existingBlock
                        hasNewTransactions = true
                    }
                }

                existingBlock.synced = true
            }
        } else {
            let validBlocks = headerHandler.getValidBlocks(headers: [blockHeader], realm: realm)

            if let validationError = validBlocks.error {
                throw validationError
            }

            if let block = validBlocks.blocks.first {
                block.synced = true

                try realm.write {
                    realm.add(block)

                    for transaction in transactions {
                        if let existingTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).first {
                            existingTransaction.block = block
                        } else {
                            realm.add(transaction)
                            transaction.block = block
                            hasNewTransactions = true
                        }
                    }
                }
            } else {
                throw HandleError.invalidBlockHeader
            }
        }

        print("HANDLE: \(transactions.count) --- \(Thread.current)")
        if hasNewTransactions {
            processor.enqueueRun()
        }
    }

    func handle(memPoolTransactions transactions: [Transaction]) throws {
        guard !transactions.isEmpty else {
            return
        }

        let realm = realmFactory.realm

        var hasNewTransactions = false

        try realm.write {
            for transaction in transactions {
                if realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).first == nil {
                    realm.add(transaction)
                    hasNewTransactions = true
                }
            }
        }

        if hasNewTransactions {
            processor.enqueueRun()
        }
    }

}
