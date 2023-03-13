import RxSwift
import RxRelay
import MarketKit
import EvmKit

class ContactBookService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactBookManager

    private var filter: String = ""

    private let contactNotAvailableRelay = PublishRelay<Bool>()
    private(set) var contactNotAvailable = false {
        didSet {
            contactNotAvailableRelay.accept(contactNotAvailable)
        }
    }

    private let contactRelay = PublishRelay<[Contact]>()
    private var _contacts: [Contact] = [] {
        didSet {
            contactRelay.accept(contacts)
        }
    }

    var contacts: [Contact] {
        guard !filter.isEmpty else {
            return _contacts
                    .sorted { contact, contact2 in contact.name < contact2.name }
        }

        return _contacts
                .filter { contact in contact.name.lowercased().contains(filter.lowercased()) }
                .sorted { contact, contact2 in contact.name < contact2.name }
    }

    init(contactManager: ContactBookManager) {
        self.contactManager = contactManager

        subscribe(disposeBag, contactManager.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        if let contacts = contactManager.contacts {
            _contacts = contacts
        } else {
            contactNotAvailable = true
        }
    }

}

extension ContactBookService {

    var contactObservable: Observable<[Contact]> {
        contactRelay.asObservable()
    }

    var contactNotAvailableObservable: Observable<Bool> {
        contactNotAvailableRelay.asObservable()
    }

    func set(filter: String) {
        self.filter = filter

        contactRelay.accept(contacts)
    }

    func update(contact: Contact) {
        do {
            try contactManager.update(contact: contact)
        } catch {
            // something wrong with store contact
            contactNotAvailable = true
        }
    }

    func delete(contactUid: String) {
        do {
            try contactManager.delete(contactUid)
        } catch {
            // something wrong with store contact
            contactNotAvailable = true
        }
    }

}
