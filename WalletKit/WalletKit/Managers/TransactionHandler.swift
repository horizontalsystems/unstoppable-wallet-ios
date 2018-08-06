import Foundation

class TransactionHandler  {
    enum HandleError: Error {
        case transactionNotFound
    }

    static let shared = TransactionHandler()

    let realmFactory: RealmFactory
    let extractor: TransactionExtractor
    let saver: TransactionSaver
    let linker: TransactionLinker

    init(realmFactory: RealmFactory = .shared, extractor: TransactionExtractor = .shared, saver: TransactionSaver = .shared, linker: TransactionLinker = .shared) {
        self.realmFactory = realmFactory
        self.extractor = extractor
        self.saver = saver
        self.linker = linker
    }

    func handle(transaction: Transaction) throws {
        try extractor.extract(message: transaction)

        let realm = realmFactory.realm
        let existingTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).last
        transaction.block = existingTransaction?.block

        try saver.save(transaction: transaction)
        try linker.handle(transaction: transaction)
    }

}
