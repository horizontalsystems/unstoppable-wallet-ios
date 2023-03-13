import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class ContactBookViewModel {
    private let service: ContactBookService
    private let disposeBag = DisposeBag()

    private let notFoundVisibleRelay = BehaviorRelay<Bool>(value: false)

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private var viewItems: [ViewItem] = [] {
        didSet {
            viewItemsRelay.accept(viewItems)
        }
    }

    init(service: ContactBookService) {
        self.service = service

        subscribe(disposeBag, service.contactObservable) { [weak self] in self?.sync(contacts: $0) }
        sync(contacts: service.contacts)
    }

    private func sync(contacts: [Contact]) {
        viewItems = contacts.map { contact in
            ViewItem(
                    uid: contact.uid,
                    title: contact.name,
                    tag: nil,
                    subtitle: "contacts.list.addresses_count".localized(contact.addresses.count),
                    showDisclosure: false
            )
        }
        notFoundVisibleRelay.accept(viewItems.isEmpty)
    }

}

extension ContactBookViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var notFoundVisibleDriver: Driver<Bool> {
        notFoundVisibleRelay.asDriver()
    }

    func updateContact(contact: Contact) {
        service.update(contact: contact)
    }

    func removeContact(contactUid: String?) {
        if let contactUid {
            service.delete(contactUid: contactUid)
        }
    }

    func onUpdate(filter: String?) {
        service.set(filter: filter ?? "")
    }

}

extension ContactBookViewModel {

    struct ViewItem {
        let uid: String
        let title: String
        let tag: String?
        let subtitle: String
        let showDisclosure: Bool

        var descrtiption: String {
            uid + title + (tag ?? "") + subtitle + showDisclosure.description
        }
    }

}
