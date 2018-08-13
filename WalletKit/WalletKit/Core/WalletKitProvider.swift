import Foundation
import RealmSwift

public class WalletKitProvider {
    private let realmFactory: RealmFactory

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory

        transactionsNotificationToken = realmFactory.realm.objects(Transaction.self).filter("isMine = %@", true).observe { [weak self] changes in
            self?.onTransactionsChanged(changes: changes)
        }
    }

    private var transactionListeners = [TransactionListener]()
    private var transactionsNotificationToken: NotificationToken?

    public func add(transactionListener: TransactionListener) {
        transactionListeners.append(transactionListener)
    }

    private func onTransactionsChanged(changes: RealmCollectionChange<Results<Transaction>>) {
        if case let .update(transactions, _, insertions, modifications) = changes {
            transactionListeners.forEach { listener in
                listener.inserted(transactions: insertions.map { transactions[$0] })
                listener.modified(transactions: modifications.map { transactions[$0] })
            }
        }
    }

    deinit {
        transactionsNotificationToken?.invalidate()
    }

}

public protocol TransactionListener {
    func inserted(transactions: [Transaction])
    func modified(transactions: [Transaction])
}
