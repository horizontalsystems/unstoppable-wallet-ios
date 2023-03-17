import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class ContactBookAddressViewModel {
    private let disposeBag = DisposeBag()

    private let service: ContactBookAddressService

    private let viewItemRelay = BehaviorRelay<String?>(value: nil)
    private var viewItem: String? {
        didSet {
            viewItemRelay.accept(viewItem)
        }
    }
    private let blockchainNameRelay = BehaviorRelay<String>(value: "")
    private let addressCautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let saveEnabledRelay = BehaviorRelay<Bool>(value: false)

    init(service: ContactBookAddressService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.selectedBlockchainObservable) { [weak self] in self?.sync(blockchain: $0) }
        sync(blockchain: service.selectedBlockchain)
    }

    private func sync(state: ContactBookAddressService.State) {
        var saveEnabled = false

        switch state {
        case .idle, .loading: ()
        case .valid(let item):
            saveEnabled = true
            viewItem = viewItem(item: item)
        case .invalid:
            addressCautionRelay.accept(Caution(text: "contacts.contact.add_address.already_in_use", type: .error))
        }

        saveEnabledRelay.accept(saveEnabled)
    }

    private func sync(blockchain: Blockchain) {
        blockchainNameRelay.accept(blockchain.name)
    }

    private func viewItem(item: ContactAddress) -> String {
        item.address
    }

}

extension ContactBookAddressViewModel {

    var existAddress: Bool {
        switch service.mode {
        case .edit: return true
        case .create: return false
        }
    }

    var title: String {
        switch service.mode {
        case .edit: return service.selectedBlockchain.name
        case .create: return "contacts.contact.add_address".localized
        }
    }

    var initialAddress: String? {
        service.initialAddress?.address
    }

    var contactAddress: ContactAddress? {
        if case let .valid(item) = service.state {
            return ContactAddress(blockchainUid: item.blockchainUid, address: item.address)
        }
        return nil
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

    var addressCautionDriver: Driver<Caution?> {
        addressCautionRelay.asDriver()
    }

    var saveEnabledDriver: Driver<Bool> {
        saveEnabledRelay.asDriver()
    }

    func setBlockchain(index: Int) {
        if let blockchain = service.unusedBlockchains.at(index: index) {
            service.selectedBlockchain = blockchain
        }
    }
}

extension ContactBookAddressService.ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .duplicate(let contact): return "contacts.add_address.exist_address".localized(contact.name)
        case .invalidAddress: return nil
        }
    }
}
