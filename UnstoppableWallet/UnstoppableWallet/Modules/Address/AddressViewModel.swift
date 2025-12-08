import Combine
import Foundation
import MarketKit

class AddressViewModel: ObservableObject {
    private let recentlySentManager = Core.shared.recentlySentManager

    let token: Token
    let destination: Destination
    let contacts: [Contact]
    let recentContact: Contact?

    private var cancellables = Set<AnyCancellable>()

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            syncAddressState()
        }
    }

    @Published private(set) var state: State = .empty

    init(token: Token, destination: AddressViewModel.Destination, address: String?) {
        self.token = token
        self.destination = destination

        let contacts = Core.shared.contactManager.contacts(blockchainUid: token.blockchainType.uid)
            .compactMap { contact -> Contact? in
                guard let address = contact.address(blockchainUid: token.blockchainType.uid) else {
                    return nil
                }

                return Contact(uid: contact.uid, name: contact.name, address: address.address)
            }
            .sorted { $0.name ?? "" < $1.name ?? "" }

        let recentAddress = recentlySentManager.recentlySent ? try? Core.shared.recentAddressStorage.address(blockchainUid: token.blockchainType.uid) : nil

        recentContact = recentAddress.map { address in
            Contact(uid: "recent", name: contacts.first(where: { $0.address.lowercased() == address.lowercased() })?.name, address: address)
        }

        self.contacts = contacts

        defer {
            if let address {
                self.address = address
            }
        }
    }

    private func syncAddressState() {
        switch addressResult {
        case .idle:
            state = .empty
        case .loading:
            state = .invalid(nil)
        case .invalid:
            state = .invalid(nil)
        case let .valid(success):
            if case let .send(fromAddress) = destination, fromAddress == success.address.raw, !token.sendToSelfAllowed {
                state = .invalid(CautionNew(
                    title: "send.address.invalid_address".localized,
                    text: "send.address_error.own_address".localized(token.coin.code),
                    type: .error
                ))
            } else {
                state = .valid(address: success.address)
            }
        }
    }
}

extension AddressViewModel {
    enum State: Equatable {
        case empty
        case invalid(CautionNew?)
        case valid(address: Address)
    }

    enum Destination {
        case swap
        case send(fromAddress: String?)

        var sourceStatPage: StatPage {
            switch self {
            case .swap: return .send
            default: return .swap
            }
        }
    }

    struct Contact: Identifiable {
        let uid: String
        let name: String?
        let address: String

        var id: String {
            uid
        }
    }
}
