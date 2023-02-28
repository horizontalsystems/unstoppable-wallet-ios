import Foundation
import RxSwift
import RxRelay
import MarketKit

class AddressBookContactService {
    private let disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let contactManager: ContactManager

    let oldContact: Contact?

    var contactName: String = "" {
        didSet {
            sync()
        }
    }

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let allAddressesUsedRelay = BehaviorRelay<Bool>(value: false)
    private var allAddressesUsed = false {
        didSet {
            syncAddresses()
        }
    }

    private(set) var addresses: [ContactAddress] = []

    init(contactManager: ContactManager, marketKit: MarketKit.Kit, contact: Contact? = nil) {
        self.marketKit = marketKit
        self.contactManager = contactManager
        oldContact = contact

        restoreContainer()
        sync()
    }

    private func restoreContainer() {
        contactName = oldContact?.name ?? ""
        addresses = oldContact?.addresses ?? []
    }

    private func blockchain(by address: ContactAddress) -> Blockchain? {
        try? marketKit.blockchain(uid: address.blockchainUid)
    }

    private func sync() {
        if contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

            state = .idle
            return
        }

        let otherContactNames = contactManager
                .contacts?
                .filter { (oldContact?.name ?? "") != $0.name }
                .map { $0.name.lowercased() } ?? []

        if otherContactNames.contains(contactName.lowercased()) || contactName == "Anton" {
            state = .error(ValidationError.nameExist)
            return
        }

        let addresses = addresses.compactMap { address -> AddressItem? in
            blockchain(by: address).map { AddressItem(blockchain: $0, address: address.address) }
        }

        if addresses.isEmpty {
            state = .idle
            return
        }

        state = .filled(Item(name: contactName, addresses: addresses))
    }

    private func syncAddresses() {
        let usedBlockchainTypes = addresses.compactMap { blockchain(by: $0)?.type }

        // check if all blockchains has adresses
        allAddressesUsed = BlockchainType
                   .supported
                   .filter({ type in
                       !usedBlockchainTypes.contains(type)
                   }).count == 0
    }

}

extension AddressBookContactService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var allAddressesUsedObservable: Observable<Bool> {
        allAddressesUsedRelay.asObservable()
    }

}

extension AddressBookContactService {

    struct AddressItem {
        let blockchain: Blockchain
        let address: String
    }

    struct Item {
        let name: String
        let addresses: [AddressItem]
    }

    enum State {
        case idle
        case filled(Item)
        case error(Error)
    }

    enum ValidationError: Error {
        case nameExist
    }

}
