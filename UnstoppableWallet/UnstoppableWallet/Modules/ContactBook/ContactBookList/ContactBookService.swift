import RxSwift
import RxRelay
import MarketKit
import EvmKit

class ContactBookService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactBookManager
    private let blockchainType: BlockchainType?

    private var filter: String = ""

    private let emptyRelay = BehaviorRelay<Bool>(value: false)
    private let itemsRelay = PublishRelay<[Item]>()
    private var _contacts: [Contact] = [] {
        didSet {
            itemsRelay.accept(items)
            emptyRelay.accept(_contacts.isEmpty)
        }
    }

    var items: [Item] {
        let contacts: [Contact]

        // append filter by name
        if !filter.isEmpty {
            contacts = _contacts.filter { contact in contact.name.lowercased().contains(filter.lowercased()) }
        } else {
            contacts = _contacts
        }

        // append readonly filter by blockchain (for select one of contact address)
        let items: [Item]
        if let blockchainType {
            items = contacts.compactMap { contact -> Item? in
                if let address = contact.addresses.first(where: { $0.blockchainUid == blockchainType.uid }) {
                    return ReadOnlyItem(uid: contact.uid, name: contact.name, address: address.address)
                }
                return nil
            }
        } else {
            items = contacts.map { contact -> Item in
                EditableItem(uid: contact.uid, name: contact.name, addressCount: contact.addresses.count)
            }
        }

        // sort items
        return items.sorted()
    }

    init(contactManager: ContactBookManager, blockchainType: BlockchainType?) {
        self.contactManager = contactManager
        self.blockchainType = blockchainType

        subscribe(disposeBag, contactManager.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        if let contacts = contactManager.all {
            _contacts = contacts
        } else {
            // todo: show alert ?
            print("Can't load contacts!")
        }
    }

}

extension ContactBookService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var emptyObservable: Observable<Bool> {
        emptyRelay.asObservable()
    }

    func set(filter: String) {
        self.filter = filter

        itemsRelay.accept(items)
    }

    func delete(contactUid: String) throws {
        try contactManager.delete(contactUid)
    }

}

extension ContactBookService {

    class Item: Comparable {
        let uid: String
        let name: String

        init(uid: String, name: String) {
            self.uid = uid
            self.name = name
        }

        static func <(lhs: Item, rhs: Item) -> Bool {
            lhs.name < rhs.name
        }

        static func ==(lhs: Item, rhs: Item) -> Bool {
            lhs.uid == rhs.uid
        }
    }

    class ReadOnlyItem: Item {
        let blockchainAddress: String

        init(uid: String, name: String, address: String) {
            self.blockchainAddress = address
            super.init(uid: uid, name: name)
        }
    }

    class EditableItem: Item {
        let addressCount: Int

        init(uid: String, name: String, addressCount: Int) {
            self.addressCount = addressCount
            super.init(uid: uid, name: name)
        }
    }

}
