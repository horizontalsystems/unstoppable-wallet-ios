import Foundation
import CloudKit
import RxSwift
import RxRelay
import ObjectMapper

class ContactManager {
    private let filename = "Contacts.json"
    static let localUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let iCloudUrl = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.io.horizontalsystems.bank-wallet.dev")?.appendingPathComponent("Documents")

    let disposeBag = DisposeBag()

    private let localStorage: LocalStorage
    private let remoteSyncRelay = PublishRelay<Bool>()
    var remoteSync: Bool {
        get {
            localStorage.remoteSync
        }
        set {
            if localStorage.remoteSync != newValue {
                localStorage.remoteSync = newValue
                remoteSyncRelay.accept(remoteSync)
                updateRemoteStorage()
            }
        }
    }

//    private var contactMetadataQuery: NSMetadataQuery?
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

    private(set) var lastTimestampSync: TimeInterval?
    private let fileStorage = FileDataStorage()

    private let localUrl: URL
    private let iCloudUrl: URL? = ContactManager.iCloudUrl

    init?(localStorage: LocalStorage) {
        guard let localUrl = ContactManager.localUrl else {
            return nil
        }

        self.localStorage = localStorage
        self.localUrl = localUrl

        sync()
//        contactMetadataQuery = NSMetadataQuery()
//        contactMetadataQuery?.notificationBatchingInterval = 1
//        contactMetadataQuery?.searchScopes = [NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope]
//        contactMetadataQuery?.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, filename)
//        contactMetadataQuery?.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)]
//        contactMetadataQuery?.start()

//        NotificationCenter.default.addObserver(self, selector: #selector(queryDidUpdate(_:)), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: contactMetadataQuery)
    }

//    @objc private func queryDidUpdate(_ notification: Notification) {
//        print("Changes!")
//    }

    func sync() {
        state = .loading

//        print("=C-SERVICE> SYNC")
        fileStorage
                .read(directoryUrl: localUrl, filename: filename)
                .subscribe(onSuccess:  { [weak self] data in
//                    print("=C-SERVICE> Found data: \(data.hs.hex)")
                    self?.sync(localData: data)
                }, onError: { [weak self] error in
//                    print("=C-SERVICE> Found error: \(error)")
                    self?.sync(localError: error)
                })
                .disposed(by: disposeBag)
    }

    private func sync(localData: Data) {
        // use local data as base contact data. Parse contacts and store it in state if possible
        do {
//            print("=C-SERVICE> Parse data")
            let contactBook = try parse(data: localData)
//            print("=C-SERVICE> Found contacts: T = \(contactBook.timestamp) \(contactBook.contacts)")

            if localStorage.remoteSync, let iCloudUrl {
                print("=C-SERVICE> Try read remote book")
                iCloudNotAvailable = nil
                fileStorage
                        .read(directoryUrl: iCloudUrl, filename: filename)
                        .subscribe(onSuccess: { [weak self] data in
//                            print("=C-SERVICE> Found remote data: \(data.hs.hex)")
                            self?.sync(iCloudData: data, contactBook: contactBook)
                        }, onError: { [weak self] error in
//                            print("=C-SERVICE> Found error: \(error)")
                            self?.sync(iCloudError: error, contactBook: contactBook)
                        })
                        .disposed(by: disposeBag)
            } else {
                state = .completed(contactBook)
            }
        } catch {
            state = .failed(error)
        }

    }

    private func sync(localError: Error) {
        if let localError = localError as? NSError, // code = 260 "No such file or directory"
           localError.domain == NSCocoaErrorDomain,
           localError.code == 260 {

            sync(localData: Data())
            return
        }

        state = .failed(localError)
    }

    private func sync(iCloudData: Data, contactBook: ContactBook) {
        do {
//            print("=C-SERVICE> Try to parse remote data")
            let remoteContactBook = try parse(data: iCloudData)
//            print("=C-SERVICE> Found remote contacts: T = \(remoteContactBook.timestamp) \(remoteContactBook.contacts)")

            // check if iCloud data newer than local. Need to save iCloud book to local storage
            if remoteContactBook.timestamp > contactBook.timestamp {
//                print("Need to save remote to local")
                try save(url: localUrl, remoteContactBook)
                state = .completed(remoteContactBook)
                return
            }
            // no need to change contact book. Use local data
            state = .completed(contactBook)

            // check if iCloud book older than local. Need to update remote book
            if let iCloudUrl, remoteContactBook.timestamp < contactBook.timestamp {
//                print("Need to save local to remote")
                try save(url: iCloudUrl, contactBook)
            }
        } catch {
            iCloudNotAvailable = error
        }
    }

    private func sync(iCloudError: Error, contactBook: ContactBook) {
        state = .completed(contactBook)

        let iCloudError = iCloudError as NSError

        if let iCloudUrl,
            iCloudError.domain == NSCocoaErrorDomain,
            iCloudError.code == 260 {           // code = 260 "No such file or directory"

            // we need to try save local contacts to iCloud file
            if !contactBook.contacts.isEmpty {
                try? save(url: iCloudUrl, contactBook)
            }
            return
        }

        iCloudNotAvailable = iCloudError
    }

    private func updateRemoteStorage() {
//        print("remoteSync :", remoteSync)
        if localStorage.remoteSync {
            //reload and update files if needed
            sync()
        } else {
            // just try to remove file from icloud. In other devices, local file will be uploaded again if needed
            fileStorage.deleteFile(url: iCloudUrl)
                    .subscribe()
                    .disposed(by: disposeBag)
        }
    }

    private func parse(data: Data) throws -> ContactBook {
//        print("Data = \(data.hs.hexString)")
        // check empty data
        guard !data.isEmpty else {
            return .empty
        }

        // try to create json with parsed data
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
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

//        print("save book to storage : URL: \(url)")
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
//            print("save book to icloud storage")
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
//            print("save book to icloud storage")
            try save(url: iCloudUrl, newContactBook)
        }
    }

}

extension ContactManager {

    enum StorageError: Error {
        case notInitialized
        case notAvailable
        case notReady
        case cantParseData
    }

}
