import Foundation
import RealmSwift
import RxSwift

class TransactionProcessor {
    let realmFactory: RealmFactory
    let extractor: TransactionExtractor
    let linker: TransactionLinker
    let logger: Logger

    init(realmFactory: RealmFactory, extractor: TransactionExtractor, linker: TransactionLinker, logger: Logger) {
        self.realmFactory = realmFactory
        self.extractor = extractor
        self.linker = linker
        self.logger = logger
    }

    func process(hexes: [String]) throws {
        print("PROCESS: \(hexes.count) --- \(Thread.current)")

        let realm = realmFactory.realm
        let pubKeys = realm.objects(PublicKey.self)

        let transactions = realm.objects(Transaction.self).filter("reversedHashHex IN %@", hexes)

        for transaction in transactions {
            try realm.write {
                try extractor.extract(transaction: transaction)
                linker.handle(transaction: transaction, realm: realm, pubKeys: pubKeys)
                transaction.processed = true
            }
        }
    }

}
