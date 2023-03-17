import Foundation
import RxSwift
import RxRelay
import RxCocoa

class ContactBookContactViewModel {
    private let disposeBag = DisposeBag()

    private let service: ContactBookContactService

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private var viewItem: ViewItem? {
        didSet {
            viewItemRelay.accept(viewItem)
        }
    }

    private let addressViewItemsRelay = BehaviorRelay<[AddressViewItem]>(value: [])
    private var addressViewItems: [AddressViewItem] = [] {
        didSet {
            addressViewItemsRelay.accept(addressViewItems)
        }
    }

    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let nameAlreadyExistErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: ContactBookContactService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.addressItemsObservable) { [weak self] in self?.sync(addressItems: $0) }
    }

    private func sync(state: ContactBookContactService.State) {
        var doneEnabled = false
        var nameAlreadyExist = false
        switch state {
        case .idle: ()
        case .updated:
            doneEnabled = true
        case .error:
            nameAlreadyExist = true
        }

        saveEnabledRelay.accept(doneEnabled)
        nameAlreadyExistErrorRelay.accept(nameAlreadyExist)
    }

    private func sync(addressItems: [ContactBookContactService.AddressItem]) {
        addressViewItems = addressItems.sorted { item, item2 in
                    if item.edited != item2.edited {
                        return item.edited
                    }
                    return item.blockchain.type.order < item2.blockchain.type.order
                }
                .map { viewItem(item: $0) }
    }

    private func viewItem(item: ContactBookContactService.AddressItem) -> AddressViewItem {
        AddressViewItem(
                blockchainUid: item.blockchain.uid,
                blockchainImageUrl: item.blockchain.type.imageUrl,
                blockchainName: item.blockchain.name,
                address: item.address,
                edited: item.edited
        )
    }

}

extension ContactBookContactViewModel {

    var existAddresses: [ContactAddress] {
        service.addresses
    }

    var editExisting: Bool {
        service.oldContact != nil
    }

    var title: String {
        service.oldContact?.name ?? "contacts.contact.new.title".localized
    }

    var contactUid: String? {
        service.oldContact?.uid
    }

    var initialName: String? {
        service.oldContact?.name
    }

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var addressViewItemsDriver: Driver<[AddressViewItem]> {
        addressViewItemsRelay.asDriver()
    }

    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    var nameAlreadyExistErrorDriver: Driver<Bool> {
        nameAlreadyExistErrorRelay.asDriver()
    }

    var hideAddAddressDriver: Driver<Bool> {
        service.allAddressesUsedObservable.asDriver(onErrorJustReturn: false)
    }

    func onChange(name: String?) {
        service.contactName = name ?? ""
    }

    func updateContact(address: ContactAddress) {
        service.updateContact(address: address)
    }

    func removeContact(address: ContactAddress?) {
        service.removeContact(address: address)
    }

    func save() throws {
        try service.save()
    }

    func delete() throws {
        try service.delete()
    }

}

extension ContactBookContactViewModel {

    struct AddressViewItem {
        let blockchainUid: String
        let blockchainImageUrl: String
        let blockchainName: String
        let address: String
        let edited: Bool
    }

    struct ViewItem {
        let name: String
        let addresses: [AddressViewItem]
    }

}
