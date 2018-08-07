import Foundation
import RxSwift
import RealmSwift

class SyncManager {
    static let shared = SyncManager()

    enum SyncStatus {
        case syncing
        case synced
        case error
    }

    private let disposeBag = DisposeBag()

    let syncSubject = BehaviorSubject<SyncStatus>(value: .synced)

    private var status: SyncStatus = .synced {
        didSet {
            syncSubject.onNext(status)
        }
    }

    private func initialSync() {
        status = .syncing
    }

}
