//import Foundation
//import RxSwift
//import RxRelay
//import RxCocoa
//
//class AddressBookAddressViewModel {
//    private let disposeBag = DisposeBag()
//
//    private let service: AddressBookAddressService
//
//    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
//    private var viewItem: ViewItem? {
//        didSet {
//            viewItemRelay.accept(viewItem)
//        }
//    }
//
//    private let doneEnabledRelay = BehaviorRelay<Bool>(value: false)
//    private let nameAlreadyExistErrorRelay = BehaviorRelay<Bool>(value: false)
//
//    init(service: AddressBookAddressService) {
//        self.service = service
//
//        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
//    }
//
//    private func sync(state: AddressBookAddressService.State) {
//        var doneEnabled = false
//        var nameAlreadyExist = false
//        switch state {
//        case .idle: ()
//        case .filled(let item):
//            doneEnabled = true
//            viewItem = viewItem(item: item)
//        case .error:
//            nameAlreadyExist = true
//        }
//
//        doneEnabledRelay.accept(doneEnabled)
//        nameAlreadyExistErrorRelay.accept(nameAlreadyExist)
//    }
//
//    private func viewItem(item: AddressBookAddressService.Item) -> ViewItem {
//        let addresses = item.addresses.map { item in
//            AddressViewItem(
//                    blockchainImageUrl: item.blockchain.type.imageUrl,
//                    blockchainName: item.blockchain.name,
//                    address: item.address,
//                    edited: false
//            )
//        }
//
//        return ViewItem(name: item.name, addresses: addresses)
//    }
//
//}
//
//extension AddressBookAddressViewModel {
//
//    var title: String {
//        service.oldContact?.name ?? "New Contact".localized
//    }
//
//    var initialName: String? {
//        service.oldContact?.name
//    }
//
//    var viewItemDriver: Driver<ViewItem?> {
//        viewItemRelay.asDriver()
//    }
//
//    var saveEnabledDriver: Driver<Bool> {
//        doneEnabledRelay.asDriver()
//    }
//
//    var nameAlreadyExistErrorDriver: Driver<Bool> {
//        nameAlreadyExistErrorRelay.asDriver()
//    }
//
//    var allAddressesUsedDriver: Driver<Bool> {
//        service.allAddressesUsedObservable.asDriver(onErrorJustReturn: true)
//    }
//
//    func onChange(name: String?) {
//        service.contactName = name ?? ""
//    }
//}
//
//extension AddressBookAddressViewModel {
//
//    struct AddressViewItem {
//        let blockchainImageUrl: String
//        let blockchainName: String
//        let address: String
//        let edited: Bool
//    }
//
//    struct ViewItem {
//        let name: String
//        let addresses: [AddressViewItem]
//    }
//
//}
