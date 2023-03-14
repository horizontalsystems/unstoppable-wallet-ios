import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class ContactBookViewModel {
    private let service: ContactBookService
    private let disposeBag = DisposeBag()

    private let emptyRelay = BehaviorRelay<Bool>(value: false)
    private let notFoundVisibleRelay = BehaviorRelay<Bool>(value: false)

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private var viewItems: [ViewItem] = [] {
        didSet {
            viewItemsRelay.accept(viewItems)
        }
    }

    init(service: ContactBookService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.emptyObservable) { [weak self] in self?.emptyRelay.accept($0) }
        sync(items: service.items)
    }

    private func sync(items: [ContactBookService.Item]) {
        viewItems = items.map { item in
            switch item {
            case let item as ContactBookService.ReadOnlyItem:
                    return SelectorViewItem(
                            uid: item.uid,
                            title: item.name,
                            subtitle: item.blockchainAddress.shortened,
                            showDisclosure: false,
                            address: item.blockchainAddress
                    )
            case let item as ContactBookService.EditableItem:
                    return ViewItem(
                            uid: item.uid,
                            title: item.name,
                            subtitle: item.addressCount.description,
                            showDisclosure: false
                    )
            default:
                return ViewItem(uid: item.uid, title: item.name, subtitle: "", showDisclosure: true)
            }
        }

        notFoundVisibleRelay.accept(viewItems.isEmpty)
    }

}

extension ContactBookViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var emptyDriver: Driver<Bool> {
        emptyRelay.asDriver()
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

    class ViewItem {
        let uid: String
        let title: String
        let subtitle: String
        let showDisclosure: Bool

        init(uid: String, title: String, subtitle: String, showDisclosure: Bool) {
            self.uid = uid
            self.title = title
            self.subtitle = subtitle
            self.showDisclosure = showDisclosure
        }

        var description: String {
            uid + title + subtitle + showDisclosure.description
        }
    }

    class SelectorViewItem: ViewItem {
        let address: String
        init(uid: String, title: String, subtitle: String, showDisclosure: Bool, address: String) {
            self.address = address
            super.init(uid: uid, title: title, subtitle: subtitle, showDisclosure: showDisclosure)
        }
    }

}
