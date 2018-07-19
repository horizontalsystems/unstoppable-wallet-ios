import Foundation

class MerkleBlockSaver {
    static let shared = MerkleBlockSaver()

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func save(block: Block, message: MerkleBlockMessage) {
//        let realm = realmFactory.realm
//
//        let transactions = [Transaction]
//
//        try? realm.write {
//            realm.add(transactions, update: true)
//        }
    }

}
