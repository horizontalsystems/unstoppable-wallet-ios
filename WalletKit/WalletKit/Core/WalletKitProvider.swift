import Foundation
import RealmSwift

public class WalletKitProvider {
    public static let shared = WalletKitProvider()

    private let realmFactory: RealmFactory

    private var transactionListeners = [TransactionListener]()

    private var transactionsNotificationToken: NotificationToken?

    init(realmFactory: RealmFactory = Singletons.shared.realmFactory) {
        self.realmFactory = realmFactory

        let realm = realmFactory.realm

        transactionsNotificationToken = realm.objects(Transaction.self).filter("isMine = %@", true).observe { [weak self] changes in
            self?.onTransactionsChanged(changes: changes)
        }
    }

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

    func preFillInitialTestData() {
        let wallet = WalletKitManager.shared.hdWallet
        var addresses = [Address]()

        for i in 0..<10 {
            if let address = try? wallet.receiveAddress(index: i) {
                addresses.append(address)
            }
            if let address = try? wallet.changeAddress(index: i) {
                addresses.append(address)
            }
        }

        let realm = realmFactory.realm
        try? realm.write {
            realm.add(addresses, update: true)
        }
    }

}

public protocol TransactionListener {
    func inserted(transactions: [Transaction])
    func modified(transactions: [Transaction])
}
