import Foundation
import RealmSwift
import RxSwift

class TransactionProcessor {
    private let realmFactory: RealmFactory
    private let extractor: TransactionExtractor
    private let linker: TransactionLinker
    private let addressManager: AddressManager
    private let logger: Logger
    private let queue: DispatchQueue

    init(realmFactory: RealmFactory, extractor: TransactionExtractor, linker: TransactionLinker, addressManager: AddressManager, logger: Logger, queue: DispatchQueue = DispatchQueue(label: "TransactionWorker", qos: .background)) {
        self.realmFactory = realmFactory
        self.extractor = extractor
        self.linker = linker
        self.addressManager = addressManager
        self.logger = logger
        self.queue = queue
    }

    func enqueueRun() {
        queue.async {
            do {
                try self.run()
            } catch {
                self.logger.log(tag: "Transaction Processor Error", message: "\(error)")
            }
        }
    }

    private func run() throws {
        let realm = realmFactory.realm

        let unprocessedTransactions = realm.objects(Transaction.self).filter("processed = %@", false)

        if !unprocessedTransactions.isEmpty {
            try realm.write {
                for transaction in unprocessedTransactions {
                    try extractor.extract(transaction: transaction)
                    linker.handle(transaction: transaction, realm: realm)
                    transaction.processed = true
                }
            }

            try addressManager.generateKeys()
        }
    }

}
