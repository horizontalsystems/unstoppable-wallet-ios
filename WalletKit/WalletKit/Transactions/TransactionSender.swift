import Foundation
import RealmSwift
import RxSwift

class TransactionSender {
    let realmFactory: RealmFactory
    let peerGroup: PeerGroup
    private let queue: DispatchQueue

    init(realmFactory: RealmFactory, peerGroup: PeerGroup, queue: DispatchQueue = DispatchQueue(label: "TransactionSender", qos: .background)) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup
        self.queue = queue
    }

    func enqueueRun() {
        queue.async {
            self.run()
        }
    }

    private func run() {
        let realm = realmFactory.realm

        let nonSentTransactions = realm.objects(Transaction.self).filter("status = %@", TransactionStatus.new.rawValue)

        for transaction in nonSentTransactions {
            peerGroup.relay(transaction: transaction)
        }
    }

}
