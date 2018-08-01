import Foundation

class TransactionHandler  {
    enum HandleError: Error {
        case transactionNotFound
    }

    static let shared = TransactionHandler()

    let realmFactory: RealmFactory
    let validator: TransactionValidator
    let saver: TransactionSaver

    init(realmFactory: RealmFactory = .shared, validator: TransactionValidator = .shared, saver: TransactionSaver = .shared) {
        self.realmFactory = realmFactory
        self.validator = validator
        self.saver = saver
    }

    func handle(transaction: Transaction) throws {
        try validator.validate(message: transaction)

        let realm = realmFactory.realm
        let reversedHashHex = Crypto.sha256sha256(transaction.serialized()).reversedHex
        let existingTransaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", reversedHashHex).last
        try saver.save(transaction: transaction, toExistingTransaction: existingTransaction)
    }

}
