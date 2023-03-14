import Foundation
import CloudKit
import RxSwift
import RxRelay
import ObjectMapper
import HsToolKit
import MarketKit

class ContactBookManager {
    static private let batchingInterval: TimeInterval = 1
    static private let filename = "Contacts.json"

    static let localUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let iCloudUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.contact_manager")

    private let disposeBag = DisposeBag()
    private var monitorDisposeBag = DisposeBag()

    private let localStorage: LocalStorage
    private let helper: ContactBookHelper
    private let logger: Logger?

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
    private(set) var state: DataStatus<ContactBook> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let fileStorage = FileDataStorage()

    private let localUrl: URL
    private let iCloudUrl: URL? = ContactBookManager.iCloudUrl

    private var needsToSyncRemote = false {
        didSet {
            logger?.debug("=C-MANAGER: set needsToRemoteUpdate \(needsToSyncRemote)))")
        }
    }

    init?(localStorage: LocalStorage, helper: ContactBookHelper, logger: Logger? = nil) {
        guard let localUrl = ContactBookManager.localUrl else {
            return nil
        }

        logger?.debug("=C-MANAGER> INIT")
        self.localStorage = localStorage
        self.helper = helper
        self.localUrl = localUrl
        self.logger = logger

        logger?.debug("=C-MANAGER> Want to Sync LocalFile")

        updateRemoteStorage()
        syncLocalFile()
    }

//  ================================ LOCAL ==================================================== //
    func syncLocalFile() {
        state = .loading

        logger?.debug("=C-MANAGER> SYNC")
        fileStorage
                .read(directoryUrl: localUrl, filename: Self.filename)
                .observeOn(scheduler)
                .subscribe(onSuccess:  { [weak self] data in
                    self?.logger?.debug("=C-MANAGER> FOUND LOCAL: \(data.count)")
                    self?.sync(localData: data)
                }, onError: { [weak self] error in
                    self?.logger?.debug("=C-MANAGER> FOUND LOCAL ERROR: \(error)")
                    self?.sync(localError: error)
                })
                .disposed(by: disposeBag)
    }

    private func sync(localData: Data) {
        // use local data as base contact data. Parse contacts and store it in state if possible
        do {
            let contactBook = try parse(data: localData)
            logger?.debug("=C-MANAGER> Found LOCAL CONTACTS: \(contactBook.contacts.count)")

            state = .completed(contactBook)

            if needsToSyncRemote {
                needsToSyncRemote = false
                syncRemoteStorage()
            }
        } catch {
            state = .failed(error)
        }
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

// ================================== REMOTE =================================================== //
    private func syncCloudFile(localBook: ContactBook) {
        if let iCloudUrl {
            logger?.debug("=C-MANAGER> Try read remote book")
            iCloudNotAvailable = nil
            try? fileStorage.prepareUbiquitousItem(url: iCloudUrl, filename: Self.filename)

            fileStorage
                    .read(directoryUrl: iCloudUrl, filename: Self.filename)
                    .observeOn(scheduler)
                    .subscribe(onSuccess: { [weak self] data in
                        self?.logger?.debug("=C-MANAGER> Found remote data: \(data.count)")
                        self?.sync(iCloudData: data, localBook: localBook)
                    }, onError: { [weak self] error in
                        self?.logger?.debug("=C-MANAGER> Found error: \(error)")
                        self?.sync(iCloudError: error, localBook: localBook)
                    })
                    .disposed(by: disposeBag)
            return
        }

        iCloudNotAvailable = StorageError.cloudUrlNotAvailable
    }

    private func saveToICloud(book: ContactBook) throws {
        logger?.debug("=C-MANAGER> Save resolved to icloud")
        guard let iCloudUrl else {
            return
        }

        metadataMonitor?.disableUpdates()
        try save(url: iCloudUrl, book)
        metadataMonitor?.enableUpdates()
    }

    private func sync(iCloudData: Data, localBook: ContactBook) {
        do {
            // if there no local book yet, just get empty. When it's come from local - resync change localfile
            logger?.debug("=C-MANAGER> LOCAL BOOK : \(localBook.contacts.count)")

            logger?.debug("=C-MANAGER> Try to parse remote data")
            let remoteContactBook = try parse(data: iCloudData)
            logger?.debug("=C-MANAGER> Found remote contacts: \(remoteContactBook.contacts)")

            // if timestamps is equal we just use local book as cache
            let result = helper.resolved(lhs: localBook, rhs: remoteContactBook)
            switch result {
            case .equal:
                state = .completed(localBook)
                logger?.debug("=C-MANAGER> Same files no need to do")
                return
            case .left:
                logger?.debug("=C-MANAGER> Local book is up to date. Save to icloud")
                state = .completed(localBook)
                try saveToICloud(book: localBook)
                return
            case .right:
                logger?.debug("=C-MANAGER> Remote book is up to date. Save to local")
                try save(url: localUrl, remoteContactBook)
                state = .completed(remoteContactBook)
            case .merged(let book):
                logger?.debug("=C-MANAGER> Merged. Save to both")
                try save(url: localUrl, book)
                state = .completed(book)

                try saveToICloud(book: book)
            }
        } catch {
            iCloudNotAvailable = error
        }
    }

    private func sync(iCloudError: Error, localBook: ContactBook) {
        // if there no local book yet, just get empty. When it's come from local - resync change localfile
        logger?.debug("=C-MANAGER> LOCAL BOOK : \(localBook.contacts.count)")

        state = .completed(localBook)

        let iCloudError = iCloudError as NSError

        if iCloudError.domain == NSCocoaErrorDomain,
            iCloudError.code == 260 {           // code = 260 "No such file or directory"

            logger?.debug("=C-MANAGER> no file in icloud. Try to save local to icloud")
            // we need to try save local contacts to iCloud file
            if !localBook.contacts.isEmpty {
                try? saveToICloud(book: localBook)
            }
            return
        }

        iCloudNotAvailable = iCloudError
    }

    private func syncRemoteStorage() {
        guard let localBook = state.data else {
            needsToSyncRemote = true
            return
        }

        syncCloudFile(localBook: localBook)
    }

    private func updateRemoteStorage() {
        logger?.debug("=C-MANAGER> UPDATE REMOTE: \(remoteSync)")
        monitorDisposeBag = DisposeBag()

        if localStorage.remoteContactsSync, let iCloudUrl {

            // create monitor and handle its events
            let metadataMonitor = MetadataMonitor(url: iCloudUrl, filename: Self.filename, batchingInterval: Self.batchingInterval, logger: logger)
            self.metadataMonitor = metadataMonitor
            logger?.debug("=C-MANAGER> Turn ON monitor")
            subscribe(scheduler, disposeBag, metadataMonitor.itemUpdatedObservable) { [weak self] updated in
                if updated {
                    self?.logger?.debug("=C-MANAGER> Monitor Want to Sync iCloudStorage")
                    self?.syncRemoteStorage()
                }
            }

            syncRemoteStorage() // sometimes monitor not ask to check icloud file, but we need to check it for first time
        } else {
            logger?.debug("=C-MANAGER> Turn Off Monitor")
            metadataMonitor = nil
        }
    }

    private func parse(data: Data) throws -> ContactBook {
        logger?.debug("=C-MANAGER> Parse Data to ContactBook")
        // check empty data
        guard !data.isEmpty else {
            logger?.debug("=C-MANAGER> DataEmpty")
            return .empty
        }

        // try to create json with parsed data
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            logger?.debug("=C-MANAGER> CANT PARSE")
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

        logger?.debug("=C-MANAGER> Save Book to Url: \(url.path)")
        fileStorage
                .write(directoryUrl: url, filename: Self.filename, data: jsonData)
                .subscribe(
                        onSuccess: { [weak self] in self?.state = .completed(book) },
                        onError: { [weak self] in self?.state = .failed($0) }
                )
                .disposed(by: disposeBag)
    }

}

extension ContactBookManager {

    var stateObservable: Observable<DataStatus<ContactBook>> {
        stateRelay.asObservable()
    }

    var all: [Contact]? {
        state.data?.contacts
    }

    func contacts(blockchainType: BlockchainType) -> [Contact] {
        guard let all else {
            return []
        }

        return all.filter { contact in
            !contact.addresses.filter({ address in
                        address.blockchainUid == blockchainType.uid
            }).isEmpty
        }
    }

    func update(contact: Contact) throws {
        guard let contactBook = state.data else {
            throw StorageError.notReady
        }

        let newContactBook = helper.update(contact: contact, book: contactBook)

        try save(url: localUrl, newContactBook)
        if remoteSync {
            try saveToICloud(book: newContactBook)
        }

    }

    func delete(_ contactUid: String) throws {
        guard let contactBook = state.data else {
            throw StorageError.notReady
        }

        let newContactBook = helper.remove(contactUid: contactUid, book: contactBook)

        try save(url: localUrl, newContactBook)
        if remoteSync {
            try saveToICloud(book: newContactBook)
        }
    }

}

extension ContactBookManager {

    enum StorageError: Error {
        case notInitialized
        case cloudUrlNotAvailable
        case notReady
        case cantParseData
    }

}
