import Foundation

class TransactionHandler  {
    enum HandleError: Error {
        case transactionNotFound
    }

    static let shared = TransactionHandler()

    let realmFactory: RealmFactory
    let validator: TransactionValidator
    let saver: TransactionSaver
    let linker: TransactionLinker

    init(realmFactory: RealmFactory = .shared, validator: TransactionValidator = .shared, saver: TransactionSaver = .shared, linker: TransactionLinker = .shared) {
        self.realmFactory = realmFactory
        self.validator = validator
        self.saver = saver
        self.linker = linker
    }

    func handle(transaction: Transaction) throws {
        try validator.validate(message: transaction)

        let reversedHashHex = Crypto.sha256sha256(transaction.serialized()).reversedHex

        let realm = realmFactory.realm
        let existingTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", reversedHashHex).last
        transaction.block = existingTransaction?.block

        try saver.save(transaction: transaction)
        try linker.linkOutpoints(transaction: transaction)
    }

}
