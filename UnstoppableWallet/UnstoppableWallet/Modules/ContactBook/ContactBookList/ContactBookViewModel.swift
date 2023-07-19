import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class ContactBookViewModel {
    private let service: ContactBookService
    private let disposeBag = DisposeBag()

    private let emptyListRelay = BehaviorRelay<ViewItemListType?>(value: nil)

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private var viewItems: [ViewItem] = [] {
        didSet {
            viewItemsRelay.accept(viewItems)
        }
    }

    init(service: ContactBookService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
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
                            subtitle: "contacts.list.addresses_count".localized(item.addressCount),
                            showDisclosure: false
                    )
            default:
                return ViewItem(uid: item.uid, title: item.name, subtitle: "", showDisclosure: true)
            }
        }

        if viewItems.isEmpty {
            emptyListRelay.accept(service.emptyBook ? .emptyBook : .emptySearch)
        } else {
            emptyListRelay.accept(nil)
        }
    }

}

extension ContactBookViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var showBadgeDriver: Driver<Bool> {
        service.iCloudAvailableErrorObservable.asDriver(onErrorJustReturn: true)
    }

    var emptyListDriver: Driver<ViewItemListType?> {
        emptyListRelay.asDriver()
    }

    func contactAddress(contactUid: String, blockchainUid: String) -> ContactAddress? {
        service.contactAddress(contactUid: contactUid, blockchainUid: blockchainUid)
    }

    func removeContact(contactUid: String?) throws {
        if let contactUid {
            try service.delete(contactUid: contactUid)
        }
    }

    func onUpdate(filter: String?) {
        service.set(filter: filter ?? "")
    }

    func blockchainName(blockchainUid: String) -> String? {
        service.blockchainName(blockchainUid: blockchainUid)
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

    enum ViewItemListType {
        case emptyBook
        case emptySearch
    }

}
