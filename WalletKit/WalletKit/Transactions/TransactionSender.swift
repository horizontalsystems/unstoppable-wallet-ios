import Foundation
import RealmSwift
import RxSwift

class TransactionSender {
    let disposeBag = DisposeBag()

    let realmFactory: RealmFactory
    let peerGroup: PeerGroup

    private var notificationToken: NotificationToken?

    init(realmFactory: RealmFactory, peerGroup: PeerGroup, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background), queue: DispatchQueue = .global(qos: .background)) {
        self.realmFactory = realmFactory
        self.peerGroup = peerGroup

        peerGroup.statusSubject
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] status in
                    if status == .connected {
                        self?.resend()
                    }
                }).disposed(by: disposeBag)

        notificationToken = realmFactory.realm.objects(Transaction.self).filter("status = %@", TransactionStatus.new.rawValue).observe { changes in
            queue.async { [weak self] in
                if case let .update(transactions, _, insertions, _) = changes, !insertions.isEmpty {
                    if !insertions.isEmpty {
                        self?.resend(transactions: transactions)
                    }
                }
            }
        }
    }

    private func resend(transactions: Results<Transaction>? = nil) {
        let realm = realmFactory.realm

        let nonSentTransactions = transactions ?? realm.objects(Transaction.self).filter("status = %@", TransactionStatus.new.rawValue)

        if !nonSentTransactions.isEmpty {
            nonSentTransactions.forEach {
                peerGroup.relay(transaction: $0)
            }
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

}
