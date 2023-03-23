import RxRelay
import RxSwift

class ContactBookSyncSettingsService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactBookManager

    private let activatedChangedRelay = BehaviorRelay<Bool>(value: false)
    private let confirmationRelay = PublishRelay<()>()

    private let cloudErrorRelay = PublishRelay<Error?>()
    var cloudError: Error? {
        didSet {
            cloudErrorRelay.accept(cloudError)
        }
    }

    private var needToMerge: Bool {     // when remote sync not enabled yet and user has contacts
        !(contactManager.remoteSync || (contactManager.all?.isEmpty ?? true))
    }

    init(contactManager: ContactBookManager) {
        self.contactManager = contactManager

        sync(error: contactManager.iCloudError)
    }

    private func sync(error: Error?) {
        cloudError = error
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

    var cloudErrorObservable: Observable<Error?> {
        cloudErrorRelay.asObservable()
    }

    func toggle(isOn: Bool) {
        // if user want's to disable, just save state
        guard isOn else {
            activated = false
            return
        }

        // if user try turn on, but icloud has error state, show alert and reset switch
        if let error = contactManager.iCloudError {
            cloudError = error
            return
        }

        // if no any errors show confirmation or activate immediately
        if needToMerge {
            confirmationRelay.accept(())
        } else {
            activated = true
        }
    }

    var confirmationObservable: Observable<()> {
        confirmationRelay.asObservable()
    }

    func confirm() {
        activated = true
    }

}
