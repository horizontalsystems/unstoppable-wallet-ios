import Foundation

class TransactionHandler {
    enum HandleError: Error {
        case transactionNotFound
    }

    let realmFactory: RealmFactory
    let extractor: TransactionExtractor
    let saver: TransactionSaver
    let linker: TransactionLinker

    init(realmFactory: RealmFactory, extractor: TransactionExtractor, saver: TransactionSaver, linker: TransactionLinker) {
        self.realmFactory = realmFactory
        self.extractor = extractor
        self.saver = saver
        self.linker = linker
    }

    func handle(transaction: Transaction) throws {
        try extractor.extract(message: transaction)
        print("-------------")
        print(transaction.outputs.first?.scriptType.rawValue)
        print(transaction.outputs.first?.keyHash?.hex)
        print(transaction.reversedHashHex)

        let realm = realmFactory.realm
        let existingTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).last
        transaction.block = existingTransaction?.block

        try saver.save(transaction: transaction)
        try linker.handle(transaction: transaction)
    }

}
