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
                if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                    self?.resend()
                }
            }
        }
    }

    private func resend() {
        let realm = realmFactory.realm

        let nonSentTransactions = realm.objects(Transaction.self).filter("status = %@", TransactionStatus.new.rawValue)

        if !nonSentTransactions.isEmpty {
            // send again
        }
    }

    deinit {
        notificationToken?.invalidate()
    }

}
