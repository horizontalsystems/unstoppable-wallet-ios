import Foundation

class TransactionSaver {
    static let shared = TransactionSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func update(transaction: Transaction?, withContentsOf message: TransactionMessage) throws {
//        let realm = realmFactory.realm


    }

}
