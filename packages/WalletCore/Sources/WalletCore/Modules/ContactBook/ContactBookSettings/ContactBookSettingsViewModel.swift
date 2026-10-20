import Combine
import Foundation
import ObjectMapper

class ContactBookSettingsViewModel: ObservableObject {
    private let contactManager = Core.shared.contactManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var syncEnabled: Bool
    @Published private(set) var lostSynchronization = false
    @Published private(set) var awaitingMergeConfirmation = false
    @Published private(set) var hasContacts = false
    @Published var pendingRestore: [BackupContact]?

    let mergeConfirmationSubject = PassthroughSubject<Void, Never>()
    let restoredSubject = PassthroughSubject<Void, Never>()
    let errorSubject = PassthroughSubject<String, Never>()

    init() {
        syncEnabled = contactManager.remoteSync

        subscribe(&cancellables, contactManager.iCloudErrorPublisher) { [weak self] error in
            self?.syncLostSynchronization(error: error)
        }
        subscribe(&cancellables, contactManager.statePublisher) { [weak self] _ in
            self?.syncHasContacts()
        }

        syncLostSynchronization(error: contactManager.iCloudError)
        syncHasContacts()
    }

    private var needToMerge: Bool {
        !(contactManager.remoteSync || (contactManager.all?.isEmpty ?? true))
    }

    private func syncHasContacts() {
        hasContacts = !(contactManager.state.data?.contacts.isEmpty ?? true)
    }

    private func syncLostSynchronization(error: Error?) {
        if case .cloudUrlNotAvailable = error as? ContactBookManager.StorageError {
            lostSynchronization = true
        } else {
            lostSynchronization = false
        }
    }
}

extension ContactBookSettingsViewModel {
    var toggleOn: Bool {
        syncEnabled || awaitingMergeConfirmation
    }

    func onToggle(isOn: Bool) {
        defer {
            syncEnabled = contactManager.remoteSync
        }

        guard isOn else {
            contactManager.remoteSync = false
            return
        }

        if let error = contactManager.iCloudError {
            syncLostSynchronization(error: error)
            return
        }

        if needToMerge {
            awaitingMergeConfirmation = true
            mergeConfirmationSubject.send()
        } else {
            contactManager.remoteSync = true
        }
    }

    func confirmMerge() {
        awaitingMergeConfirmation = false
        contactManager.remoteSync = true
        syncEnabled = contactManager.remoteSync
    }

    func cancelMerge() {
        awaitingMergeConfirmation = false
        syncEnabled = contactManager.remoteSync
    }

    func didPick(result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else {
                return
            }

            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let contacts = try contactManager.backupContacts(from: url)
                pendingRestore = contacts
            } catch {
                errorSubject.send("contacts.restore.parsing_error".localized)
            }
        case let .failure(error):
            if case CocoaError.userCancelled = error {
                return
            }

            errorSubject.send("contacts.restore.parsing_error".localized)
        }
    }

    func restore(contacts: [BackupContact]) {
        do {
            try contactManager.restore(contacts: contacts, mergePolitics: .replace)
            restoredSubject.send()
        } catch {
            errorSubject.send("contacts.restore.restore_error".localized)
        }
    }

    func createBackupFile() -> URL? {
        do {
            guard let backupBook = contactManager.backupContactBook else {
                throw CreateBackupFileError.noBackupContactBook
            }

            let jsonData = try JSONSerialization.data(withJSONObject: backupBook.contacts.toJSON())

            guard let temporaryFileUrl = ContactBookManager.localUrl?.appendingPathComponent("ContactBook.json") else {
                throw CreateBackupFileError.noTempFileUrl
            }

            try jsonData.write(to: temporaryFileUrl)

            return temporaryFileUrl
        } catch {
            errorSubject.send("contacts.restore.storage_error".localized)
            return nil
        }
    }
}

extension ContactBookSettingsViewModel {
    enum CreateBackupFileError: Error {
        case noBackupContactBook
        case noTempFileUrl
    }
}
