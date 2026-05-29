import Combine
import Foundation
import MarketKit

class AddressViewModel: ObservableObject {
    private let recentlySentManager = Core.shared.recentlySentManager

    let token: Token
    let destination: Destination
    let initialAddress: String
    let contacts: [Contact]
    let recentContact: Contact?
    let securityCheckViewModel: AddressSecurityCheckViewModel
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
        initialAddress = address ?? ""
        securityCheckViewModel = AddressSecurityCheckViewModel(token: token)

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

        securityCheckViewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] checkState in
                self?.syncFromCheckState(checkState)
            }
            .store(in: &cancellables)
    }

    private func syncAddressState() {
        switch addressResult {
        case .idle:
            state = .empty
            securityCheckViewModel.check(address: nil)
        case .loading:
            state = .invalid(nil)
            securityCheckViewModel.check(address: nil)
        case .invalid:
            state = .invalid(nil)
            securityCheckViewModel.check(address: nil)
        case let .valid(success):
            if case let .send(fromAddress) = destination, fromAddress == success.address.raw, !token.sendToSelfAllowed {
                state = .invalid(CautionNew(
                    title: "send.address.invalid_address".localized,
                    text: "send.address_error.own_address".localized(token.coin.code),
                    type: .error
                ))
                securityCheckViewModel.check(address: nil)
            } else {
                securityCheckViewModel.check(address: success.address)
            }
        }
    }

    private func syncFromCheckState(_ checkState: AddressSecurityCheckViewModel.State) {
        switch checkState {
        case .idle:
            ()
        case .checking:
            state = .checking
        case let .completed(address, detectedTypes):
            state = .valid(resolvedAddress: ResolvedAddress(address: address.raw, issueTypes: detectedTypes))
        }
    }
}

extension AddressViewModel {
    enum State: Equatable {
        case empty
        case invalid(CautionNew?)
        case checking
        case valid(resolvedAddress: ResolvedAddress)
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
