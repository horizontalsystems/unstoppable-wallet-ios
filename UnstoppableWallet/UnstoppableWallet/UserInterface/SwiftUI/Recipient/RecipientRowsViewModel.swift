import Foundation
import MarketKit
import RxSwift

class RecipientRowsViewModel: ObservableObject {
    let disposeBag = DisposeBag()
    let evmLabelManager = Core.shared.evmLabelManager
    let manager = Core.shared.contactManager

    let address: String
    let customTitle: String?
    let blockchainType: BlockchainType

    @Published var item: Item

    init(address: String, customTitle: String?, blockchainType: BlockchainType) {
        self.address = address
        self.customTitle = customTitle
        self.blockchainType = blockchainType
        item = RecipientRowsViewModel.item(address: address, customTitle: customTitle, blockchainType: blockchainType)

        subscribe(disposeBag, Core.shared.contactManager.stateObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        item = Self.item(address: address, customTitle: customTitle, blockchainType: blockchainType)
    }

    var emptyContacts: Bool {
        manager.all?.isEmpty ?? true
    }
}

extension RecipientRowsViewModel {
    private static func item(address: String, customTitle: String?, blockchainType: BlockchainType) -> Item {
        if let title = customTitle {
            return .custom(title, address: address)
        } else if let contact = Core.shared.contactManager.all?.by(address: address, blockchainUid: blockchainType.uid) {
            return .contact(contact.name, address: address)
        } else if let label = Core.shared.evmLabelManager.addressLabel(address: address) {
            return .label(label, address: address)
        } else {
            return .raw(address: address)
        }
    }
}

extension RecipientRowsViewModel {
    enum AddAddressType: String, Identifiable {
        case create, add

        var id: String { rawValue }
    }

    enum Item {
        case raw(address: String)
        case label(String, address: String)
        case contact(String, address: String)
        case custom(String, address: String)

        var icon: String {
            switch self {
            case .raw, .custom: return "wallet_filled"
            case .label: return "list_filled" // TODO: change to some label-icon
            case .contact: return "user_filled"
            }
        }

        var title: String {
            switch self {
            case let .raw(address): return address
            case let .label(name, _): return name
            case let .contact(name, _): return name
            case let .custom(title, _): return title
            }
        }

        var subtitle: String? {
            switch self {
            case .raw: return nil
            case let .label(_, address): return address
            case let .contact(_, address): return address
            case let .custom(_, address): return address
            }
        }
    }
}

extension RecipientRowsViewModel: ContactBookSelectorDelegate {
    func onFetch(address _: String) {}
}
