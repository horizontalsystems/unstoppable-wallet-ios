import Foundation

class TransactionCreator {
    enum CreationError: Error {
        case noChangeAddress
        case transactionAlreadyExists
    }

    let feeRate: Int = 600

    private let realmFactory: RealmFactory
    private let transactionBuilder: TransactionBuilder
    private let transactionSender: TransactionSender

    init(realmFactory: RealmFactory, transactionBuilder: TransactionBuilder, transactionSender: TransactionSender) {
        self.realmFactory = realmFactory
        self.transactionBuilder = transactionBuilder
        self.transactionSender = transactionSender
    }

    func create(to address: String, value: Int) throws {
        let realm = realmFactory.realm

        guard let changeAddress = realm.objects(PublicKey.self).filter("outputs.@count = %@", 0).first else {
            throw CreationError.noChangeAddress
        }

        let transaction = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: false, changePubKey: changeAddress, toAddress: address)

        if realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).first != nil {
            throw CreationError.transactionAlreadyExists
        }

        try realm.write {
            realm.add(transaction)
        }

        transactionSender.enqueueRun()
    }

}
