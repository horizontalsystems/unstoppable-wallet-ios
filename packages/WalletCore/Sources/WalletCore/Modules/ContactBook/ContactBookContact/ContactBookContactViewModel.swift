import Combine
import Foundation
import MarketKit

class ContactBookContactViewModel: ObservableObject {
    private let contactManager = Core.shared.contactManager
    private let marketKit = Core.shared.marketKit

    private let oldContact: Contact?

    let title: String
    let isExisting: Bool
    let contactUid: String?

    @Published var name: String {
        didSet {
            sync()
        }
    }

    @Published private(set) var addresses: [ContactAddress] {
        didSet {
            syncAddressItems()
            sync()
            syncAllUsed()
        }
    }

    @Published private(set) var addressItems: [AddressItem] = []
    @Published private(set) var state: State = .idle
    @Published private(set) var allBlockchainsUsed = false

    init(mode: Mode) {
        let newAddresses: [ContactAddress]

        switch mode {
        case .new:
            oldContact = nil
            newAddresses = []
        case let .exist(uid, addresses):
            oldContact = Core.shared.contactManager.all?.first { $0.uid == uid }
            newAddresses = addresses
        case let .add(address):
            oldContact = nil
            newAddresses = [address]
        }

        title = oldContact?.name ?? "contacts.contact.new.title".localized
        isExisting = oldContact != nil
        contactUid = oldContact?.uid
        name = oldContact?.name ?? ""
        addresses = oldContact?.addresses ?? []

        if newAddresses.isEmpty {
            syncAddressItems()
            sync()
            syncAllUsed()
        } else {
            for address in newAddresses {
                set(address: address)
            }
        }
    }

    private func blockchain(address: ContactAddress) -> Blockchain? {
        try? marketKit.blockchain(uid: address.blockchainUid)
    }

    private func sync() {
        state = Self.state(name: name, addresses: addresses, oldContact: oldContact, allContacts: contactManager.all ?? [])
    }

    private func syncAddressItems() {
        addressItems = addresses
            .compactMap { address -> AddressItem? in
                var edited = true

                if let oldAddress = oldContact?.addresses.first(where: { $0.blockchainUid == address.blockchainUid }) {
                    edited = oldAddress.address != address.address
                }

                return blockchain(address: address).map { AddressItem(blockchain: $0, address: address.address, edited: edited) }
            }
            .sorted { lhs, rhs in
                if lhs.edited != rhs.edited {
                    return lhs.edited
                }

                return lhs.blockchain.type.order < rhs.blockchain.type.order
            }
    }

    private func syncAllUsed() {
        let usedBlockchainTypes = addresses.compactMap { blockchain(address: $0)?.type }

        allBlockchainsUsed = !usedBlockchainTypes.isEmpty && BlockchainType.supported.allSatisfy { usedBlockchainTypes.contains($0) }
    }
}

extension ContactBookContactViewModel {
    var saveEnabled: Bool {
        state == .updated
    }

    var hasChanges: Bool {
        name != (oldContact?.name ?? "") || addresses != (oldContact?.addresses ?? [])
    }

    var firstUnusedBlockchain: Blockchain? {
        let blockchainUids = BlockchainType.supported
            .map(\.uid)
            .filter { uid in !addresses.contains { $0.blockchainUid == uid } }

        return ((try? marketKit.blockchains(uids: blockchainUids)) ?? [])
            .sorted { $0.type.order < $1.type.order }
            .first
    }

    func set(address: ContactAddress) {
        if let index = addresses.firstIndex(where: { $0.blockchainUid == address.blockchainUid }) {
            addresses[index] = address
        } else {
            addresses.append(address)
        }
    }

    func remove(address: ContactAddress) {
        if let index = addresses.firstIndex(where: { $0.blockchainUid == address.blockchainUid }) {
            addresses.remove(at: index)
        }
    }

    func save() throws {
        guard state == .updated else {
            return
        }

        let contact = Contact(
            uid: oldContact?.uid ?? UUID().uuidString,
            modifiedAt: Date().timeIntervalSince1970,
            name: name,
            addresses: addresses
        )

        try contactManager.update(contact: contact)
    }

    func delete() throws {
        guard let uid = oldContact?.uid else {
            return
        }

        try contactManager.delete(uid)
    }

    static func state(name: String, addresses: [ContactAddress], oldContact: Contact?, allContacts: [Contact]) -> State {
        let otherContactNames = allContacts
            .filter { (oldContact?.name ?? "") != $0.name }
            .map { $0.name.lowercased() }

        if otherContactNames.contains(name.lowercased()) {
            return .nameExists
        }

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || addresses.isEmpty {
            return .idle
        }

        if let oldContact, name == oldContact.name, addresses == oldContact.addresses {
            return .idle
        }

        return .updated
    }
}

extension ContactBookContactViewModel {
    enum Mode {
        case new
        case exist(uid: String, newAddresses: [ContactAddress])
        case add(ContactAddress)
    }

    struct AddressItem: Identifiable {
        let blockchain: Blockchain
        let address: String
        let edited: Bool

        var id: String {
            blockchain.uid
        }
    }

    enum State: Equatable {
        case idle
        case updated
        case nameExists
    }
}
