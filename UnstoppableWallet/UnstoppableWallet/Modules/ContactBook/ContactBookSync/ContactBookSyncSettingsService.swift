import RxRelay
import RxSwift

class ContactBookSyncSettingsService {
    private let contactManager: ContactBookManager

    private let activatedChangedRelay = BehaviorRelay<Bool>(value: false)
    private let confirmationRelay = PublishRelay<()>()

    private var needToMerge: Bool {     // when remote sync not enabled yet and user has contacts
        !(contactManager.remoteSync || (contactManager.contacts?.isEmpty ?? true))
    }

    init(contactManager: ContactBookManager) {
        self.contactManager = contactManager
    }

}

extension ContactBookSyncSettingsService {

    var activated: Bool {
        get {
            contactManager.remoteSync
        }
        set {
            contactManager.remoteSync = newValue
            activatedChangedRelay.accept(newValue)
        }
    }

    var activatedChangedObservable: Observable<Bool> {
        activatedChangedRelay.asObservable()
    }

    func toggle() {
        if needToMerge {
            confirmationRelay.accept(())
        } else {
            activated = !activated
        }
    }

    var confirmationObservable: Observable<()> {
        confirmationRelay.asObservable()
    }

    func confirm() {
        activated = true
    }

}
