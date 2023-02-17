import Foundation
import StorageKit
import RxRelay
import RxSwift

class ContactManager {
    private let filename = "contacts"
    private let keyICloudSyncValue = "icloud-sync-value"

    private let queue = DispatchQueue(label: "io.contact.manager", qos: .background)

    private let localDisposeBag = DisposeBag()
    private let localStorage: LocalStorage
    private let contactStorage: ContactStorage

    private var remoteDisposeBag = DisposeBag()
    private let remoteUrl: URL?
    private var remoteContactStorage: ContactStorage?

    private let remoteSyncRelay = PublishRelay<Bool>()
    var remoteSync: Bool {
        didSet {
            remoteSyncRelay.accept(remoteSync)
            localStorage.remoteSync = remoteSync
        }
    }

    init(localStorage: LocalStorage, contactUrl: URL? = ContactStorage.localUrl, remoteUrl: URL? = ContactStorage.iCloudUrl) {
        self.localStorage = localStorage
        self.remoteUrl = remoteUrl
        remoteSync = localStorage.remoteSync

        contactStorage = ContactStorage(directoryUrl: contactUrl, filename: filename)

        subscribe(localDisposeBag, contactStorage.stateObservable) { [weak self] _ in
            self?.queue.async {
                self?.syncStorages()
            }
        }

        updateRemoteStorage()
    }

    private func updateRemoteStorage() {
        print("remoteSync :", remoteSync)
        if localStorage.remoteSync {
            let remoteContactStorage = ContactStorage(directoryUrl: remoteUrl, filename: filename)
            subscribe(localDisposeBag, remoteContactStorage.stateObservable) { [weak self] _ in
                self?.queue.async {
                    self?.syncStorages()
                }
            }
            self.remoteContactStorage = remoteContactStorage
        } else {
            remoteContactStorage?.turnOff()
            remoteContactStorage = nil
        }
    }

    private func syncStorages() {
        print("==> SYNC STORAGES: ")
        print("==> LOCAL: \(contactStorage.state) ")
        print("==> GLOBAL: \(remoteContactStorage?.state) ")

        // if all storages complete downloading, if one of it has old timestamp, we need sync last version
        guard let localBook = contactStorage.state.data,
              let remoteContactStorage,
              let remoteBook = remoteContactStorage.state.data else {
            print("==> Dont need sync")
            return
        }
        let lastTimestampSync = contactStorage.lastTimestampSync ?? 0
        let remoteLastTimestampSync = remoteContactStorage.lastTimestampSync ?? 0

        print("LOCAL LAST: \(lastTimestampSync) - GLOBAL lAST: \(remoteLastTimestampSync)")
        if lastTimestampSync > remoteLastTimestampSync {
            print("COPY to Remote")
            try? remoteContactStorage.save(ContactBook(timestamp: lastTimestampSync, contacts: localBook))
        }
        if remoteLastTimestampSync > lastTimestampSync {
            print("COPY to Local")
            try? contactStorage.save(ContactBook(timestamp: lastTimestampSync, contacts: remoteBook))
        }
    }

}

extension ContactManager {

    var remoteSyncObservable: Observable<Bool> {
        remoteSyncRelay.asObservable()
    }

    var contacts: [Contact]? {
        contactStorage.state.data
    }

    func update(contact: Contact) throws {
        print("Try to update contact: \(contact.name)")
        let actualTimestamp = try contactStorage.update(contact)

        try remoteContactStorage?.update(contact, timestamp: actualTimestamp)
    }

}
