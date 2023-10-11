import Foundation
import RxRelay
import RxSwift

class ContactBookSettingsService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactBookManager

    private let activatedChangedRelay = BehaviorRelay<Bool>(value: false)
    private let confirmationRelay = PublishRelay<()>()

    private let cloudErrorRelay = BehaviorRelay<Error?>(value: nil)
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

        subscribe(disposeBag, contactManager.iCloudErrorObservable) { [weak self] error in
            self?.sync(error: error)
        }
        sync(error: contactManager.iCloudError)
    }

    private func sync(error: Error?) {
        cloudError = error
    }

}

extension ContactBookSettingsService {

    var hasContacts: Bool {
        guard let contactBook = contactManager.state.data else {
            return false
        }

        return !contactBook.contacts.isEmpty
    }

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

    func backupContacts(from url: URL) throws -> [BackupContact] {
        try contactManager.backupContacts(from: url)
    }

    func replace(contacts: [BackupContact]) throws {
        try contactManager.restore(contacts: contacts, mergePolitics: .replace)
    }

    func createBackupFile() throws -> URL {
        // make simple book json.
        guard let backupBook = contactManager.backupContactBook else {
            throw CreateBackupFileError.noBackupContactBook
        }

        let jsonData = try JSONSerialization.data(withJSONObject: backupBook.contacts.toJSON())

        // save book to temporary file
        guard let temporaryFileUrl = ContactBookManager.localUrl?.appendingPathComponent("ContactBook.json") else {
            throw CreateBackupFileError.noTempFileUrl
        }

        try jsonData.write(to: temporaryFileUrl)

        return temporaryFileUrl
    }

}

extension ContactBookSettingsService {

    enum CreateBackupFileError: Error {
        case noBackupContactBook
        case noTempFileUrl
    }

}
