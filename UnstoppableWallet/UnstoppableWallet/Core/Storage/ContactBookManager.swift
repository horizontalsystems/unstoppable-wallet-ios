import CloudKit
import Combine
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import RxRelay
import RxSwift

class ContactBookManager {
    private static let batchingInterval: TimeInterval = 1
    static let filename = "Contacts.json"

    static let localUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).contact_manager")

    private let ubiquityContainerIdentifier: String?

    private var monitorCancellables = Set<AnyCancellable>()

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

    private let iCloudErrorRelay = BehaviorRelay<Error?>(value: nil)
    private(set) var iCloudError: Error? {
        didSet {
            iCloudErrorRelay.accept(iCloudError)
        }
    }

    private let stateRelay = PublishRelay<DataStatus<ContactBook>>()
    private(set) var state: DataStatus<ContactBook> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let fileStorage = FileStorage()

    let localUrl: URL?
    var iCloudUrl: URL? {
        FileManager
            .default
            .url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
            .appendingPathComponent("Documents")
    }

    private var needsToSyncRemote = false {
        didSet {
            logger?.debug("=C-MANAGER: set needsToRemoteUpdate \(needsToSyncRemote)))")
        }
    }

    init(localStorage: LocalStorage, ubiquityContainerIdentifier: String?, helper: ContactBookHelper, logger: Logger? = nil) {
        self.ubiquityContainerIdentifier = ubiquityContainerIdentifier

        logger?.debug("=C-MANAGER> INIT")
        self.localStorage = localStorage
        self.helper = helper
        localUrl = ContactBookManager.localUrl
        self.logger = logger

        logger?.debug("=C-MANAGER> Want to Sync LocalFile")

        updateRemoteStorage()
        syncLocalFile()
    }

    //  ================================ LOCAL ==================================================== //
    func syncLocalFile() {
        state = .loading
        guard let localUrl else {
            state = .failed(ContactBookManager.StorageError.localUrlNotAvailable)
            return
        }

        logger?.debug("=C-MANAGER> SYNC")
        do {
            let data = try fileStorage
                .read(directoryUrl: localUrl, filename: Self.filename)
            logger?.debug("=C-MANAGER> FOUND LOCAL: \(data.count)")
            sync(localData: data)
        } catch {
            logger?.debug("=C-MANAGER> FOUND LOCAL ERROR: \(error)")
            sync(localError: error)
        }
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
            guard let localUrl else {
                state = .failed(ContactBookManager.StorageError.localUrlNotAvailable)
                return
            }

            // if file can't be parsed we need delete it and show empty book
            do {
                _ = try fileStorage.deleteFile(url: localUrl)
                logger?.debug("=C-MANAGER> REMOVE BROKEN file")
                sync(localData: Data())
            } catch {
                logger?.debug("=C-MANAGER> Can't remove broken local file")
                sync(localError: error)
            }
        }
    }

    private func sync(localError: Error) {
        let localError = localError as NSError // code = 260 "No such file or directory"

        if localError.domain == NSCocoaErrorDomain,
           localError.code == 260
        {
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
            iCloudError = nil

            try? fileStorage.prepareUbiquitousItem(url: iCloudUrl, filename: Self.filename)

            do {
                let data = try fileStorage.read(directoryUrl: iCloudUrl, filename: Self.filename)
                logger?.debug("=C-MANAGER> Found remote data: \(data.count)")
                sync(iCloudData: data, localBook: localBook)
            } catch {
                logger?.debug("=C-MANAGER> Found error: \(error)")
                sync(iCloudError: error, localBook: localBook)
            }
        } else {
            iCloudError = StorageError.cloudUrlNotAvailable
        }
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
        guard let localUrl else {
            state = .failed(ContactBookManager.StorageError.localUrlNotAvailable)
            return
        }

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
            case let .merged(book):
                logger?.debug("=C-MANAGER> Merged. Save to both")
                try save(url: localUrl, book)
                state = .completed(book)

                try saveToICloud(book: book)
            }
        } catch {
            iCloudError = error
        }
    }

    private func sync(iCloudError: Error, localBook: ContactBook) {
        // if there no local book yet, just get empty. When it's come from local - resync change localfile
        logger?.debug("=C-MANAGER> LOCAL BOOK : \(localBook.contacts.count)")

        state = .completed(localBook)

        let iCloudError = iCloudError as NSError

        if iCloudError.domain == NSCocoaErrorDomain,
           iCloudError.code == 260
        { // code = 260 "No such file or directory"
            logger?.debug("=C-MANAGER> no file in icloud. Try to save local to icloud")
            // we need to try save local contacts to iCloud file
            if !localBook.contacts.isEmpty {
                try? saveToICloud(book: localBook)
            }
            return
        }

        self.iCloudError = iCloudError
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
        monitorCancellables.forEach { cancellable in cancellable.cancel() }
        monitorCancellables.removeAll()

        // check url available
        guard let iCloudUrl else {
            logger?.debug("=C-MANAGER> UPDATE REMOTE: Has Error: \(iCloudError.map { "\($0)" } ?? "nil")!")
            iCloudError = StorageError.cloudUrlNotAvailable
            metadataMonitor = nil

            return
        }
        iCloudError = nil

        if localStorage.remoteContactsSync {
            // create monitor and handle its events
            let metadataMonitor = MetadataMonitor(url: iCloudUrl, filenames: [Self.filename], batchingInterval: Self.batchingInterval, logger: logger)
            self.metadataMonitor = metadataMonitor
            logger?.debug("=C-MANAGER> Turn ON monitor")
            metadataMonitor.needUpdatePublisher
                .sink { [weak self] in
                    self?.logger?.debug("=C-MANAGER> Monitor Want to Sync iCloudStorage")
                    self?.syncRemoteStorage()
                }
                .store(in: &monitorCancellables)

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
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
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
        do {
            try fileStorage.write(directoryUrl: url, filename: Self.filename, data: jsonData)
            state = .completed(book)
        } catch {
            state = .failed(error)
        }
    }
}

extension ContactBookManager {
    var stateObservable: Observable<DataStatus<ContactBook>> {
        stateRelay.asObservable()
    }

    var iCloudErrorObservable: Observable<Error?> {
        iCloudErrorRelay.asObservable()
    }

    var all: [Contact]? {
        state.data?.contacts
    }

    func contacts(blockchainUid: String) -> [Contact] {
        guard let all else {
            return []
        }

        return all.filter { $0.address(blockchainUid: blockchainUid) != nil }
    }

    func name(blockchainType: BlockchainType, address: String) -> String? {
        if let contact = all?.first(where: { contact in
            !contact.addresses
                .filter { $0.blockchainUid == blockchainType.uid && $0.address.lowercased() == address.lowercased() }.isEmpty
        }) {
            return contact.name
        }

        return nil
    }

    func update(contact: Contact) throws {
        guard let localUrl else {
            state = .failed(ContactBookManager.StorageError.localUrlNotAvailable)
            return
        }

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
        guard let localUrl else {
            state = .failed(ContactBookManager.StorageError.localUrlNotAvailable)
            return
        }

        guard let contactBook = state.data else {
            throw StorageError.notReady
        }

        let newContactBook = helper.remove(contactUid: contactUid, book: contactBook)

        try save(url: localUrl, newContactBook)
        if remoteSync {
            try saveToICloud(book: newContactBook)
        }
    }

    // Backup and restore section

    func backupContacts(from url: URL) throws -> [BackupContact] {
        let data = try FileManager.default.contentsOfFile(coordinatingAccessAt: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let contacts = try? json.map({ try Mapper<BackupContact>().map(JSON: $0) })
        else {
            throw StorageError.cantParseData
        }

        return contacts
    }

    func restore(contacts: [BackupContact], mergePolitics: MergePolitics) throws {
        guard let localUrl else {
            state = .failed(ContactBookManager.StorageError.localUrlNotAvailable)
            return
        }

        let resolved: ContactBook

        switch mergePolitics {
        case .replace:
            resolved = helper.contactBook(contacts: contacts, lastVersion: state.data?.version)
        case .insert:
            resolved = helper.insert(contacts: contacts, book: state.data)
        }

        try save(url: localUrl, resolved)
        if remoteSync {
            try? saveToICloud(book: resolved)
        }
    }

    var backupContactBook: BackupContactBook? {
        state.data.map { helper.backupContactBook(contactBook: $0) }
    }
}

extension ContactBookManager {
    static func encrypt(contacts: [BackupContact], passphrase: String) throws -> BackupCrypto {
        let encoder = JSONEncoder()
        let data = try encoder.encode(contacts)
        return try BackupCrypto.encrypt(data: data, passphrase: passphrase)
    }

    static func decrypt(crypto: BackupCrypto, passphrase: String) throws -> [BackupContact] {
        let data = try crypto.decrypt(passphrase: passphrase)
        let decoder = JSONDecoder()
        let contacts = try decoder.decode([BackupContact].self, from: data)

        return contacts
    }
}

extension ContactBookManager {
    enum MergePolitics {
        case replace, insert
    }

    enum StorageError: Error {
        case cloudUrlNotAvailable
        case localUrlNotAvailable
        case notReady
        case cantParseData
    }
}
