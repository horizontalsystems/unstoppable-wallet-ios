import Foundation

class TransactionCreator {
    enum CreationError: Error {
        case noChangeAddress
        case transactionAlreadyExists
    }

    let feeRate: Int = 600

    private let realmFactory: RealmFactory
    private let transactionBuilder: TransactionBuilder
    private let transactionProcessor: TransactionProcessor
    private let transactionSender: TransactionSender
    private let addressManager: AddressManager

    init(realmFactory: RealmFactory, transactionBuilder: TransactionBuilder, transactionProcessor: TransactionProcessor, transactionSender: TransactionSender, addressManager: AddressManager) {
        self.realmFactory = realmFactory
        self.transactionBuilder = transactionBuilder
        self.transactionProcessor = transactionProcessor
        self.transactionSender = transactionSender
        self.addressManager = addressManager
    }

    func create(to address: String, value: Int) throws {
        let realm = realmFactory.realm

        guard let changePubKey = try? addressManager.changePublicKey() else {
            throw CreationError.noChangeAddress
        }

        let transaction = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: false, changePubKey: changePubKey, toAddress: address)

        if realm.objects(Transaction.self).filter("reversedHashHex = %@", transaction.reversedHashHex).first != nil {
            throw CreationError.transactionAlreadyExists
        }

        try realm.write {
            realm.add(transaction)
        }

        transactionSender.enqueueRun()
        transactionProcessor.enqueueRun()
    }

}
