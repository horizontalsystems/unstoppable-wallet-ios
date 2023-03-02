import Foundation
import RxSwift
import RxRelay
import MarketKit

class AddressBookContactService {
    private let disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let contactManager: ContactManager

    let oldContact: Contact?

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let allBlockchainsUsedRelay = BehaviorRelay<Bool>(value: false)

    private let addressItemsRelay = BehaviorRelay<[AddressItem]>(value: [])
    private(set) var addresses: [ContactAddress] = [] {
        didSet {
            syncAddresses()
            sync()
            syncAllUsedBlockchains()
        }
    }

    var contactName: String = "" {
        didSet {
            sync()
        }
    }

    init(contactManager: ContactManager, marketKit: MarketKit.Kit, contact: Contact? = nil) {
        self.marketKit = marketKit
        self.contactManager = contactManager
        oldContact = contact

        restoreContainer()

        sync()
        syncAddresses()
        syncAllUsedBlockchains()
    }

    private func restoreContainer() {
        contactName = oldContact?.name ?? ""
        addresses = oldContact?.addresses ?? []
    }

    private func blockchain(by address: ContactAddress) -> Blockchain? {
        try? marketKit.blockchain(uid: address.blockchainUid)
    }

    private func syncAddresses() {
        let addressItems = addresses.compactMap { address -> AddressItem? in
                    var edited = true
                    // check if old address same with new - set edited false
                    if let oldAddresses = oldContact?.addresses,
                        let oldAddress = oldAddresses.first(where: { $0.blockchainUid == address.blockchainUid  }) {
                        edited = oldAddress.address != address.address
                    }
                    return blockchain(by: address).map { AddressItem(blockchain: $0, address: address.address, edited: edited) }
                }.sorted { item, item2 in item.blockchain.type.order < item2.blockchain.type.order }


        addressItemsRelay.accept(addressItems)
    }

    private func syncAllUsedBlockchains() {
        let usedBlockchainTypes = addresses.compactMap { blockchain(by: $0)?.type }
        guard !usedBlockchainTypes.isEmpty else {
            return
        }

        // check if all blockchains has adresses
        allBlockchainsUsedRelay.accept(
                BlockchainType
                   .supported
                   .filter({ type in
                       !usedBlockchainTypes.contains(type)
                   }).count == 0
        )
    }

    private func sync() {
        // check if name already exist
        let otherContactNames = contactManager
                .contacts?
                .filter { (oldContact?.name ?? "") != $0.name }
                .map { $0.name.lowercased() } ?? []

        if otherContactNames.contains(contactName.lowercased()) {
            state = .error(ValidationError.nameExist)
            return
        }

        // check empty name or empty addresses
        if contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || addresses.isEmpty {
            state = .idle
            return
        }
        // check no changes with old contact
        if let oldContact, contactName == oldContact.name, addresses == oldContact.addresses {
            state = .idle
            return
        }

        state = .updated
    }

}

extension AddressBookContactService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var addressItemsObservable: Observable<[AddressItem]> {
        addressItemsRelay.asObservable()
    }

    var allAddressesUsedObservable: Observable<Bool> {
        allBlockchainsUsedRelay.asObservable()
    }

    func updateContact(address: ContactAddress) {
        if let index = addresses.firstIndex(where: { $0.blockchainUid == address.blockchainUid }) {
            addresses[index] = address
        } else {
            addresses.append(address)
        }
    }

    func removeContact(address: ContactAddress?) {
        if let address, let index = addresses.firstIndex(where: { $0.blockchainUid == address.blockchainUid }) {
            addresses.remove(at: index)
        }
    }

}

extension AddressBookContactService {

    struct AddressItem {
        let blockchain: Blockchain
        let address: String
        let edited: Bool
    }

    struct Item {
        let name: String
        let addresses: [AddressItem]
    }

    enum State {
        case idle
        case updated
        case error(Error)
    }

    enum ValidationError: Error {
        case nameExist
    }

}
