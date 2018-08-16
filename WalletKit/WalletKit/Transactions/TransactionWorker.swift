import Foundation
import RealmSwift

class TransactionWorker: BackgroundWorker {
    let realmFactory: RealmFactory
    let processor: TransactionProcessor

    private var notificationToken: NotificationToken?

    init(realmFactory: RealmFactory, processor: TransactionProcessor, sync: Bool = false) {
        self.realmFactory = realmFactory
        self.processor = processor

        super.init(sync: sync)

        start { [weak self] in
            if let realm = self?.realmFactory.realm {
                self?.notificationToken = realm.objects(Transaction.self).filter("processed = %@", false).observe { changes in
                    if case let .update(transactions, _, insertions, _) = changes, !insertions.isEmpty {
                        self?.processor.process(realm: realm, transactions: transactions)
                    }
                }
            }
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

}
