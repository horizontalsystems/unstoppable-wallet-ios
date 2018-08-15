import Foundation

class TransactionCreator {
    enum CreationError: Error { case noChangeAddress }

    let feeRate: Int = 6

    let realmFactory: RealmFactory
    let transactionBuilder: TransactionBuilder

    init(realmFactory: RealmFactory, transactionBuilder: TransactionBuilder) {
        self.realmFactory = realmFactory
        self.transactionBuilder = transactionBuilder
    }

    func create(to address: String, value: Int) throws {
        let realm = realmFactory.realm

        guard let changeAddress = realm.objects(PublicKey.self).filter("outputs.@count = %@", 0).first else {
            throw CreationError.noChangeAddress
        }

        let transaction = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changePubKey: changeAddress, toAddress: address)
        try realm.write {
            realm.add(transaction, update: true)
            print("added transaction to realm")
        }
    }

}
