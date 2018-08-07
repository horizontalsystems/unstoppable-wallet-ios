import Foundation
import RealmSwift

public class WalletKitProvider {
    public static let shared = WalletKitProvider()

    private let realmFactory: RealmFactory

    private var transactionListeners = [TransactionListener]()

    private var transactionsNotificationToken: NotificationToken?

    init(realmFactory: RealmFactory = .shared) {
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
        let preCheckPointHeader = BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "000000000000021cfa27b31eaff92aa63987dfe8b42a9f3776bc9ccac4f88d5f",
                merkleRootReversedHex: "dd78fe7a00b80a6a7e47ea3dce28d8ac2a2e89bd08905b6acc0319420d70da6b",
                timestamp: 1533498013,
                bits: 436461112,
                nonce: 2271208224
        )
        let preCheckpointBlock = BlockFactory.shared.block(withHeader: preCheckPointHeader, height: 1380959)
        preCheckpointBlock.synced = true

        let checkPointHeader = BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "000000000000032d74ad8eb0a0be6b39b8e095bd9ca8537da93aae15087aafaf",
                merkleRootReversedHex: "dec6a6b395b29be37f4b074ed443c3625fac3ae835b1f1080155f01843a64268",
                timestamp: 1533498326,
                bits: 436270990,
                nonce: 205753354
        )
        let checkpointBlock = BlockFactory.shared.block(withHeader: checkPointHeader, previousBlock: preCheckpointBlock)
        checkpointBlock.synced = true

        let walletManager = WalletManager.shared
        var addresses = [Address]()

        for i in 0..<10 {
            if let address = try? walletManager.wallet.receiveAddress(index: i) {
                addresses.append(address)
            }
            if let address = try? walletManager.wallet.changeAddress(index: i) {
                addresses.append(address)
            }
        }

        let realm = realmFactory.realm
        try? realm.write {
            realm.add(preCheckpointBlock, update: true)
            realm.add(checkpointBlock, update: true)
            realm.add(addresses, update: true)
        }
    }

}

public protocol TransactionListener {
    func inserted(transactions: [Transaction])
    func modified(transactions: [Transaction])
}
