import Foundation
import RealmSwift
import RxSwift

class TransactionProcessor {
    let extractor: TransactionExtractor
    let linker: TransactionLinker
    let logger: Logger

    init(extractor: TransactionExtractor, linker: TransactionLinker, logger: Logger) {
        self.extractor = extractor
        self.linker = linker
        self.logger = logger
    }

    func process(realm: Realm, transactions: Results<Transaction>) {
        let pubKeys = realm.objects(PublicKey.self)

        do {
            for transaction in transactions {
                try realm.write {
                    try extractor.extract(transaction: transaction)
                    linker.handle(transaction: transaction, realm: realm, pubKeys: pubKeys)
                    transaction.processed = true
                }
            }
        } catch {
            logger.log(tag: "Transaction Processor Error", message: "\(error)")
        }
    }

}
