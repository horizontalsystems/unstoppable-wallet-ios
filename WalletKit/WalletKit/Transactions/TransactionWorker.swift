import Foundation
import RealmSwift

class TransactionWorker {
    let realmFactory: RealmFactory
    let processor: TransactionProcessor
    let queue: DispatchQueue

    init(realmFactory: RealmFactory, processor: TransactionProcessor, queue: DispatchQueue = DispatchQueue(label: "TransactionWorker", qos: .background)) {
        self.realmFactory = realmFactory
        self.processor = processor
        self.queue = queue

        let hexes = realmFactory.realm.objects(Transaction.self).filter("processed = %@", false).map { $0.reversedHashHex }
        if !hexes.isEmpty {
            handle(transactionHexes: Array(hexes))
        }
    }

    func handle(transactionHexes: [String]) {
        queue.async {
            do {
                try self.processor.process(hexes: transactionHexes)
            } catch {
                print("TX PROCESS ERROR: \(error)")
            }
        }
    }

}
