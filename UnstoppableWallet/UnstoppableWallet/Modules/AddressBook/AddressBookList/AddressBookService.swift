import RxSwift
import RxRelay
import MarketKit
import EvmKit

class AddressBookService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactManager

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
        }
        return _contacts.filter { contact in contact.name.contains(filter) }
    }

    init(contactManager: ContactManager) {
        self.contactManager = contactManager
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

extension AddressBookService {

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
//        do {
//            try contactManager.update(contact: contact)
//        } catch {
//            // something wrong with store contact
//            contactNotAvailable = true
//        }
    }

    func delete(contact: Contact) {
//        do {
//            try contactManager.update(contact: contact)
//        } catch {
//            // something wrong with store contact
//            contactNotAvailable = true
//        }
    }

}
