import Foundation
import CloudKit
import RxSwift
import RxRelay
import ObjectMapper

class ContactManager {
    static private let batchingInterval: TimeInterval = 1
    static let localUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let iCloudUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.contact_manager")
    private let filename = "Contacts.json"

    let disposeBag = DisposeBag()
    private var monitorDisposeBag = DisposeBag()

    private let localStorage: LocalStorage

    private let remoteSyncRelay = PublishRelay<Bool>()
    var remoteSync: Bool {
        get {
            localStorage.remoteContactsSync
        }
        set {
            if localStorage.remoteContactsSync != newValue {
                localStorage.remoteContactsSync = newValue
                remoteSyncRelay.accept(remoteSync)
                updateRemoteStorage()
            }
        }
    }

    private var metadataMonitor: MetadataMonitor?

    private let iCloudNotAvailableRelay = PublishRelay<Error?>()
    private(set) var iCloudNotAvailable: Error? = nil {
        didSet {
            iCloudNotAvailableRelay.accept(iCloudNotAvailable)
        }
    }

    private let stateRelay = PublishRelay<DataStatus<ContactBook>>()
    private(set) var state: DataStatus<ContactBook> = .completed(.empty) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let fileStorage = FileDataStorage()

    private let localUrl: URL
    private let iCloudUrl: URL? = ContactManager.iCloudUrl

    init?(localStorage: LocalStorage) {
        guard let localUrl = ContactManager.localUrl else {
            return nil
        }

        print("=C-MANAGER> INIT")
        self.localStorage = localStorage
        self.localUrl = localUrl

        print("=C-MANAGER> Want to Sync LocalFile")
        syncLocalFile()
        updateRemoteStorage()
    }

    func syncLocalFile() {
        state = .loading

        print("=C-MANAGER> SYNC")
        fileStorage
                .read(directoryUrl: localUrl, filename: filename)
                .observeOn(scheduler)
                .subscribe(onSuccess:  { [weak self] data in
                    print("=C-MANAGER> FOUND LOCAL: \(data.count)")
                    self?.sync(localData: data)
                }, onError: { [weak self] error in
                    print("=C-MANAGER> Found LOCAL ERROR: \(error)")
                    self?.sync(localError: error)
                })
                .disposed(by: disposeBag)
    }

    private func sync(localData: Data) {
        // use local data as base contact data. Parse contacts and store it in state if possible
        do {
            let contactBook = try parse(data: localData)
            print("=C-MANAGER> Found LOCAL CONTACTS: T = \(contactBook.timestamp) \(contactBook.contacts.count)")

            state = .completed(contactBook)
        } catch {
            state = .failed(error)
        }
    }

    private func syncCloudFile(localBook: ContactBook?) {
        if let iCloudUrl {
            print("=C-MANAGER> Try read remote book")
            iCloudNotAvailable = nil
            fileStorage
                    .read(directoryUrl: iCloudUrl, filename: filename)
                    .observeOn(scheduler)
                    .subscribe(onSuccess: { [weak self] data in
                        print("=C-MANAGER> Found remote data: \(data.count)")
                        self?.sync(iCloudData: data, localBook: localBook)
                    }, onError: { [weak self] error in
                        print("=C-MANAGER> Found error: \(error)")
                        self?.sync(iCloudError: error, localBook: localBook)
                    })
                    .disposed(by: disposeBag)
            return
        }

        iCloudNotAvailable = StorageError.cloudUrlNotAvailable
    }


    private func sync(localError: Error) {
        let localError = localError as NSError // code = 260 "No such file or directory"
        if localError.domain == NSCocoaErrorDomain,
           localError.code == 260 {

            sync(localData: Data())
            return
        }

        // todo. analyze if need check global data before failing
        state = .failed(localError)
    }

    private func sync(iCloudData: Data, localBook: ContactBook?) {
        do {
            // if there no local book yet, just get empty. When it's come from local - resync change localfile
            let localBook = localBook ?? state.data ?? ContactBook(timestamp: 0, contacts: [])
            print("=C-MANAGER> LOCAL BOOK T:\(localBook.timestamp) : \(localBook.contacts.count)")

            print("=C-MANAGER> Try to parse remote data")
            let remoteContactBook = try parse(data: iCloudData)
            print("=C-MANAGER> Found remote contacts: T = \(remoteContactBook.timestamp) \(remoteContactBook.contacts)")

            // if timestamps is equal we just use local book as cache
            guard remoteContactBook.timestamp != localBook.timestamp else {
                state = .completed(localBook)
                print("=C-MANAGER> Same files no need to do")
                return
            }

            // else need resolve and save new book both to local and icloud storages
            let resolvedBook = resolve(lhs: localBook, rhs: remoteContactBook)

            print("=C-MANAGER> Save resolved to local")

            try save(url: localUrl, resolvedBook)
            state = .completed(remoteContactBook)

            if let iCloudUrl {
                print("=C-MANAGER> Save resolved to icloud")
                metadataMonitor?.disableUpdates()
                try save(url: iCloudUrl, localBook)
                metadataMonitor?.enableUpdates()
            }
        } catch {
            iCloudNotAvailable = error
        }
    }

    private func resolve(lhs: ContactBook, rhs: ContactBook) -> ContactBook {
        let leftIsNew = lhs.timestamp > rhs.timestamp
        let newBook = leftIsNew ? lhs : rhs
        let oldBook = leftIsNew ? rhs : lhs

        let set = Set(newBook.contacts).union(oldBook.contacts)
        return ContactBook(timestamp: max(lhs.timestamp, rhs.timestamp), contacts: Array(set))
    }

    private func sync(iCloudError: Error, localBook: ContactBook?) {
        // if there no local book yet, just get empty. When it's come from local - resync change localfile
        let localBook = localBook ?? state.data ?? ContactBook(timestamp: 0, contacts: [])
        print("=C-MANAGER> LOCAL BOOK T:\(localBook.timestamp) : \(localBook.contacts.count)")

        state = .completed(localBook)

        let iCloudError = iCloudError as NSError

        if let iCloudUrl,
            iCloudError.domain == NSCocoaErrorDomain,
            iCloudError.code == 260 {           // code = 260 "No such file or directory"

            print("=C-MANAGER> no file in icloud. Try to save local to icloud")
            // we need to try save local contacts to iCloud file
            if !localBook.contacts.isEmpty {
                try? save(url: iCloudUrl, localBook)
            }
            return
        }

        iCloudNotAvailable = iCloudError
    }

    private func syncRemoteStorage() {
        syncCloudFile(localBook: nil)
    }

    private func updateRemoteStorage() {
        print("=C-MANAGER> UPDATE REMOTE: \(remoteSync)")
        monitorDisposeBag = DisposeBag()

        if localStorage.remoteContactsSync, let iCloudUrl {

            // create monitor and handle its events
            let metadataMonitor = MetadataMonitor(url: iCloudUrl, filename: filename, batchingInterval: 5)
            self.metadataMonitor = metadataMonitor
            print("=C-MANAGER> Turn ON monitor")
            subscribe(scheduler, disposeBag, metadataMonitor.itemUpdatedObservable) { [weak self] updated in
                if updated {
                    print("=C-MANAGER> Monitor Want to Sync iCloudStorage")
                    self?.syncRemoteStorage()
                }
            }
            syncRemoteStorage()
        } else {
            metadataMonitor = nil
            // just try to remove file from icloud. In other devices, local file will be uploaded again if needed
            print("=C-MANAGER> Turn Off Monitor")
            fileStorage.deleteFile(url: iCloudUrl)
                    .observeOn(scheduler)
                    .subscribe()
                    .disposed(by: disposeBag)
        }
    }

    private func parse(data: Data) throws -> ContactBook {
        print("=C-MANAGER> Parse Data to ContactBook")
        // check empty data
        guard !data.isEmpty else {
            print("=C-MANAGER> DataEmpty")
            return .empty
        }

        // try to create json with parsed data
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            print("=C-MANAGER> CANT PARSE")
           throw StorageError.cantParseData
        }

        let book = try Mapper<ContactBook>().map(JSON: json)
        return book
    }

    private func updatedContacts(contacts: [Contact], by contact: Contact) -> [Contact] {
        guard let index = contacts.firstIndex(of: contact) else {
            return contacts + [contact]
        }
        var newContacts = contacts
        newContacts[index] = contact
        return newContacts
    }

    private func save(url: URL, _ book: ContactBook) throws {
        let json = book.toJSON()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            throw StorageError.cantParseData
        }

        print("=C-MANAGER> Save Book to Url: \(url.path)")
        fileStorage
                .write(directoryUrl: url, filename: filename, data: jsonData)
                .subscribe(
                        onSuccess: { [weak self] in self?.state = .completed(book) },
                        onError: { [weak self] in self?.state = .failed($0) }
                )
                .disposed(by: disposeBag)
    }

}

extension ContactManager {

    var stateObservable: Observable<DataStatus<ContactBook>> {
        stateRelay.asObservable()
    }

    var contacts: [Contact]? {
        state.data?.contacts
    }

    func update(contact: Contact) throws {
        guard let contactBook = state.data else {
            throw StorageError.notReady
        }

        let newContactBook = ContactBook(
                timestamp: Date().timeIntervalSince1970,
                contacts: updatedContacts(contacts: contactBook.contacts, by: contact))

        try save(url: localUrl, newContactBook)
        if remoteSync, let iCloudUrl {
            print("save book to icloud storage")
            try save(url: iCloudUrl, newContactBook)
        }

    }

    func delete(_ contactUid: String, timestamp: TimeInterval? = nil) throws {
        guard var contacts = state.data?.contacts,
              let index = contacts.firstIndex(where: { $0.uid == contactUid }) else {

            throw StorageError.notReady
        }
        contacts.remove(at: index)

        let newContactBook = ContactBook(
                timestamp: Date().timeIntervalSince1970,
                contacts: contacts)

        try save(url: localUrl, newContactBook)
        if remoteSync, let iCloudUrl {
            try save(url: iCloudUrl, newContactBook)
        }
    }

}

extension ContactManager {

    enum StorageError: Error {
        case notInitialized
        case cloudUrlNotAvailable
        case notReady
        case cantParseData
    }

}
