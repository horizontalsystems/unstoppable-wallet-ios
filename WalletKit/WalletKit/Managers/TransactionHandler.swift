import Foundation

class TransactionHandler  {
    enum HandleError: Error {
        case transactionNotFound
    }

    static let shared = TransactionHandler()

    let storage: IStorage
    let extractor: TransactionExtractor
    let saver: TransactionSaver
    let linker: TransactionLinker

    init(storage: IStorage = RealmStorage.shared, extractor: TransactionExtractor = .shared, saver: TransactionSaver = .shared, linker: TransactionLinker = .shared) {
        self.storage = storage
        self.extractor = extractor
        self.saver = saver
        self.linker = linker
    }

    func handle(transaction: Transaction) throws {
        try extractor.extract(message: transaction)

        let existingTransaction = storage.getTransaction(byReversedHashHex: transaction.reversedHashHex)
        transaction.block = existingTransaction?.block

        try saver.save(transaction: transaction)
        try linker.linkOutpoints(transaction: transaction)
    }

}
