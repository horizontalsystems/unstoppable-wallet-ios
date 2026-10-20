import Combine
import Foundation
import MarketKit

class ContactBookAddressViewModel: ObservableObject {
    private let contactManager = Core.shared.contactManager
    private let marketKit = Core.shared.marketKit
    private let contactUid: String?

    let title: String
    let isEdit: Bool
    let initialAddress: ContactAddress?
    let blockchains: [Blockchain]

    @Published var selectedBlockchain: Blockchain {
        didSet {
            addressResult = .idle
            sync()
        }
    }

    @Published var text: String

    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            sync()
        }
    }

    @Published private(set) var state: State = .idle

    init(contactUid: String?, mode: Mode, blockchain: Blockchain) {
        self.contactUid = contactUid

        switch mode {
        case let .create(existingAddresses):
            let blockchainUids = BlockchainType.supported
                .map(\.uid)
                .filter { uid in !existingAddresses.contains { $0.blockchainUid == uid } }

            title = "contacts.contact.add_address".localized
            isEdit = false
            initialAddress = nil
            blockchains = ((try? marketKit.blockchains(uids: blockchainUids)) ?? [])
                .sorted { $0.type.order < $1.type.order }
        case let .edit(address):
            title = blockchain.name
            isEdit = true
            initialAddress = address
            blockchains = [blockchain]
        }

        selectedBlockchain = blockchain
        text = initialAddress?.address ?? ""
    }

    private func sync() {
        switch addressResult {
        case .idle:
            state = .idle
        case .loading:
            state = .loading
        case let .invalid(failure):
            state = .invalid(caution(failure: failure))
        case let .valid(success):
            if let initialAddress, success.address.raw == initialAddress.address {
                state = .idle
                return
            }

            let address = ContactAddress(blockchainUid: selectedBlockchain.uid, address: success.address.raw)

            if let contact = Self.duplicate(address: address, contacts: contactManager.all ?? [], currentContactUid: contactUid) {
                state = .invalid(CautionNew(text: "contacts.add_address.exist_address".localized(contact.name), type: .error))
            } else {
                state = .valid(address)
            }
        }
    }

    private func caution(failure: AddressInput.Failure) -> CautionNew {
        if case let AddressParserChain.ParserError.fetchError(error) = failure.error,
           let description = (error as? LocalizedError)?.errorDescription
        {
            return CautionNew(title: "send.address.invalid_address".localized, text: description, type: .error)
        }

        return CautionNew(
            title: "send.address.invalid_address".localized,
            text: AddressService.AddressError.invalidAddress(blockchainName: selectedBlockchain.name).localizedDescription,
            type: .error
        )
    }
}

extension ContactBookAddressViewModel {
    var saveEnabled: Bool {
        contactAddress != nil
    }

    var hasChanges: Bool {
        text != (initialAddress?.address ?? "")
    }

    var contactAddress: ContactAddress? {
        if case let .valid(address) = state {
            return address
        }

        return nil
    }

    static func duplicate(address: ContactAddress, contacts: [Contact], currentContactUid: String?) -> Contact? {
        contacts
            .filter { $0.uid != currentContactUid }
            .first { $0.addresses.contains(address) }
    }
}

extension ContactBookAddressViewModel {
    enum Mode {
        case create(existingAddresses: [ContactAddress])
        case edit(ContactAddress)
    }

    enum State {
        case idle
        case loading
        case valid(ContactAddress)
        case invalid(CautionNew?)
    }
}
