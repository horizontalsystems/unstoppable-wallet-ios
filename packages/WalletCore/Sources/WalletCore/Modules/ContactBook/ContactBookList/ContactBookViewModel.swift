import Combine
import Foundation
import MarketKit

class ContactBookViewModel: ObservableObject {
    private let contactManager = Core.shared.contactManager
    private let marketKit = Core.shared.marketKit
    private let blockchainType: BlockchainType?
    private var cancellables = Set<AnyCancellable>()

    @Published var filter: String = "" {
        didSet {
            sync()
        }
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var emptyState: EmptyState?
    @Published private(set) var showSettingsBadge = false

    init(blockchainType: BlockchainType?) {
        self.blockchainType = blockchainType

        subscribe(&cancellables, contactManager.statePublisher) { [weak self] _ in self?.sync() }
        subscribe(&cancellables, contactManager.iCloudErrorPublisher) { [weak self] _ in self?.syncBadge() }

        sync()
        syncBadge()
    }

    private func sync() {
        let contacts = contactManager.all ?? []
        let items = Self.items(contacts: contacts, filter: filter, blockchainType: blockchainType)

        if items.isEmpty {
            emptyState = contacts.isEmpty ? .emptyBook : .emptySearch
        } else {
            emptyState = nil
        }

        self.items = items
    }

    private func syncBadge() {
        showSettingsBadge = contactManager.iCloudError != nil && contactManager.remoteSync
    }
}

extension ContactBookViewModel {
    func contactAddress(contactUid: String, blockchainUid: String) -> ContactAddress? {
        contactManager.all?
            .first { $0.uid == contactUid }?
            .address(blockchainUid: blockchainUid)
    }

    func blockchainName(blockchainUid: String) -> String? {
        try? marketKit.blockchain(uid: blockchainUid)?.name
    }

    func delete(contactUid: String) {
        do {
            try contactManager.delete(contactUid)
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
        }
    }

    static func items(contacts: [Contact], filter: String, blockchainType: BlockchainType?) -> [Item] {
        let filtered: [Contact]

        if filter.isEmpty {
            filtered = contacts
        } else {
            filtered = contacts.filter { $0.name.lowercased().contains(filter.lowercased()) }
        }

        let items: [Item]

        if let blockchainType {
            items = filtered.compactMap { contact in
                guard let address = contact.addresses.first(where: { $0.blockchainUid == blockchainType.uid }) else {
                    return nil
                }

                return Item(id: contact.uid, name: contact.name, subtitle: address.address.shortened, address: address.address)
            }
        } else {
            items = filtered.map { contact in
                Item(id: contact.uid, name: contact.name, subtitle: "contacts.list.addresses_count".localized(contact.addresses.count), address: nil)
            }
        }

        return items.sorted { $0.name < $1.name }
    }
}

extension ContactBookViewModel {
    struct Item: Identifiable, Hashable {
        let id: String
        let name: String
        let subtitle: String
        let address: String?
    }

    enum EmptyState {
        case emptyBook
        case emptySearch
    }
}
