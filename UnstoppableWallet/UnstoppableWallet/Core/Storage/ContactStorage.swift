import Foundation
import CloudKit
import RxSwift
import RxRelay
import ObjectMapper

class ContactStorage {
    static let localUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    static let iCloudUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")

    static var directoryUrl: URL?
    let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[Contact]>>()
    private(set) var state: DataStatus<[Contact]> = .completed([]) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var lastTimestampSync: TimeInterval?
    private let fileStorage: FileStorageService

    init(directoryUrl: URL? = ContactStorage.localUrl, filename: String) {
        fileStorage = FileStorageService(directoryUrl: directoryUrl, filename: filename)

        subscribe(disposeBag, fileStorage.stateObservable) { [weak self] in self?.sync(state: $0) }
        prepareStorage()
    }

    private func sync(state: FileStorageService.State) {
        switch state {
        case .idle: self.state = .completed([])
        case .writing, .reading: self.state = .loading
        case .failed(let error): self.state = .failed(error)
        case .completed(let data): self.parse(data: data)
        }
    }

    private func prepareStorage() {
        fileStorage.prepare()
    }


    private func parse(data: Data) {
        print("Data = \(data.hs.hexString)")
        // check empty data
        guard !data.isEmpty else {
            state = .completed([])
            return
        }

        // try to create json with parsed data
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
                state = .failed(StorageError.cantParseData)
                return
            }

            let book = try Mapper<ContactBook>().map(JSON: json)
            lastTimestampSync = book.timestamp
            state = .completed(book.contacts)
        } catch let error {
            state = .failed(StorageError.cantParseData)
        }
    }

    private func updatedContacts(contacts: [Contact], by contact: Contact) -> [Contact] {
        guard let index = contacts.firstIndex(of: contact) else {
            return contacts + [contact]
        }
        var newContacts = contacts
        newContacts[index] = contact
        return newContacts
    }

}

extension ContactStorage {

    var stateObservable: Observable<DataStatus<[Contact]>> {
        stateRelay.asObservable()
    }

    func get() -> [Contact] {
        state.data ?? []
    }

    @discardableResult func update(_ contact: Contact, timestamp: TimeInterval? = nil) throws -> TimeInterval {
        guard let contacts = state.data else {
            throw StorageError.notReady
        }

        let newContacts = updatedContacts(contacts: contacts, by: contact)

        let updatedTimestamp = timestamp ?? Date().timeIntervalSince1970
        let newContactBook = ContactBook(timestamp: updatedTimestamp, contacts: newContacts)

        try save(newContactBook)
        return updatedTimestamp
    }

    func save(_ book: ContactBook) throws {
        let json = book.toJSON()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            throw StorageError.cantParseData
        }

        fileStorage.write(data: jsonData)
    }

    func turnOff() {    // delete file if possible
        fileStorage.deleteFile()
    }

}

extension ContactStorage {

    enum StorageError: Error {
        case notInitialized
        case notAvailable
        case notReady
        case cantParseData
    }

}
