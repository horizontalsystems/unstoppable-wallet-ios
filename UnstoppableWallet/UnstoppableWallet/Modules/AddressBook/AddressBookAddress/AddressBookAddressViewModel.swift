import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class AddressBookAddressViewModel {
    private let disposeBag = DisposeBag()

    private let service: AddressBookAddressService

    private let viewItemRelay = BehaviorRelay<String?>(value: nil)
    private var viewItem: String? {
        didSet {
            viewItemRelay.accept(viewItem)
        }
    }
    private let blockchainNameRelay = BehaviorRelay<String>(value: "")

    private let doneEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let nameAlreadyExistErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: AddressBookAddressService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.selectedBlockchainObservable) { [weak self] in self?.sync(blockchain: $0) }
        sync(blockchain: service.selectedBlockchain)
    }

    private func sync(state: AddressBookAddressService.State) {
        var doneEnabled = false
        var addressWrong = false

        switch state {
        case .idle, .loading: ()
        case .valid(let item):
            doneEnabled = true
            viewItem = viewItem(item: item)
        case .invalid:
            addressWrong = true
        }

        doneEnabledRelay.accept(doneEnabled)
        nameAlreadyExistErrorRelay.accept(addressWrong)
    }

    private func sync(blockchain: Blockchain) {
        blockchainNameRelay.accept(blockchain.name)
    }

    private func viewItem(item: ContactAddress) -> String {
        item.address
    }

}

extension AddressBookAddressViewModel {

    var readonly: Bool {
        switch service.mode {
        case .edit: return true
        case .create: return false
        }
    }

    var title: String {
        switch service.mode {
        case .edit: return service.selectedBlockchain.name
        case .create: return "Add Address"
        }
    }

    var initialAddress: String? {
        nil
    }

    var blockchainViewItems: [SelectorModule.ViewItem] {
        service.unusedBlockchains.map { blockchain in
            SelectorModule.ViewItem(
                    image: .url(blockchain.type.imageUrl, placeholder: "placeholder_rectangle_32"),
                    title: blockchain.name,
                    selected: service.selectedBlockchain == blockchain
            )
        }
    }

    var viewItemDriver: Driver<String?> {
        viewItemRelay.asDriver()
    }

    var blockchainNameDriver: Driver<String> {
        blockchainNameRelay.asDriver()
    }

    var saveEnabledDriver: Driver<Bool> {
        doneEnabledRelay.asDriver()
    }

    var nameAlreadyExistErrorDriver: Driver<Bool> {
        nameAlreadyExistErrorRelay.asDriver()
    }

    func onChange(address: String?) {
        service.address = address ?? ""
    }

    func setBlockchain(index: Int) {
        if let blockchain = service.unusedBlockchains.at(index: index) {
            service.selectedBlockchain = blockchain
        }
    }
}

extension AddressBookAddressViewModel {

}
