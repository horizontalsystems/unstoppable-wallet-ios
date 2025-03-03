import Combine
import Foundation
import MarketKit

class AddressViewModel: ObservableObject {
    private let purchaseManager = App.shared.purchaseManager
    let token: Token
    private let destination: Destination
    let issueTypes: [AddressSecurityIssueType]
    let contacts: [Contact]
    let recentContact: Contact?
    private var cancellables = Set<AnyCancellable>()

    private var premiumEnabled: Bool {
        didSet {
            syncAddressState()
        }
    }

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            syncAddressState()
        }
    }

    @Published private(set) var state: State = .empty

    @Published private(set) var checkStates = [AddressSecurityIssueType: CheckState]() {
        didSet {
            syncValidState()
        }
    }

    init(token: Token, destination: AddressViewModel.Destination, address: String?) {
        self.token = token
        self.destination = destination
        issueTypes = AddressSecurityIssueType.issueTypes(token: token)

        let contacts = App.shared.contactManager.contacts(blockchainUid: token.blockchainType.uid)
            .compactMap { contact -> Contact? in
                guard let address = contact.address(blockchainUid: token.blockchainType.uid) else {
                    return nil
                }

                return Contact(uid: contact.uid, name: contact.name, address: address.address)
            }
            .sorted { $0.name ?? "" < $1.name ?? "" }

        let recentAddress = try? App.shared.recentAddressStorage.address(blockchainUid: token.blockchainType.uid)

        recentContact = recentAddress.map { address in
            Contact(uid: "recent", name: contacts.first(where: { $0.address.lowercased() == address.lowercased() })?.name, address: address)
        }

        self.contacts = contacts

        premiumEnabled = purchaseManager.activated(.addressChecker)

        defer {
            if let address {
                self.address = address
            }
        }

        purchaseManager.$activeFeatures
            .sink { [weak self] features in
                self?.premiumEnabled = features.contains(.addressChecker)
            }
            .store(in: &cancellables)
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
                )
                )
            } else {
                if premiumEnabled {
                    check(address: success.address)
                } else {
                    for type in issueTypes {
                        checkStates[type] = .locked
                    }

                    state = .valid(resolvedAddress: ResolvedAddress(address: address, issueTypes: []))
                }
            }
        }
    }

    private func check(address: Address) {
        for type in issueTypes {
            checkStates[type] = .checking
        }

        state = .checking

        for type in issueTypes {
            let checker = AddressSecurityCheckerFactory.addressSecurityChecker(type: type)

            Task {
                do {
                    let hasIssue = try await checker.check(address: address, token: token)

                    await MainActor.run {
                        checkStates[type] = hasIssue ? .detected : .clear
                    }
                } catch {
                    await MainActor.run {
                        checkStates[type] = .notAvailable
                    }
                }
            }
        }
    }

    private func syncValidState() {
        guard case .checking = state else {
            return
        }

        var detectedTypes = [AddressSecurityIssueType]()

        for type in issueTypes {
            let checkState = checkStates[type] ?? .notAvailable

            switch checkState {
            case .checking:
                return
            case .detected:
                detectedTypes.append(type)
            default: ()
            }
        }

        let resolvedAddress = ResolvedAddress(address: address, issueTypes: detectedTypes)
        state = .valid(resolvedAddress: resolvedAddress)
    }
}

extension AddressViewModel {
    enum State {
        case empty
        case invalid(CautionNew?)
        case checking
        case valid(resolvedAddress: ResolvedAddress)
    }

    enum CheckState {
        case checking
        case clear
        case detected
        case notAvailable
        case locked
    }

    enum Destination {
        case swap
        case send(fromAddress: String?)
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
