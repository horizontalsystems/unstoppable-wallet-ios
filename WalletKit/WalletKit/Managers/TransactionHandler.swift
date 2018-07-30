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

    func handle(message: TransactionMessage) throws {
        try validator.validate(message: message)

        let realm = realmFactory.realm
        let reversedHashHex = Crypto.sha256sha256(message.serialized()).reversedHex
        let transaction = realm.objects(Transaction.self).filter("reversedHashHex = %@", reversedHashHex).last
        try saver.update(transaction: transaction, withContentsOf: message)
    }

}
