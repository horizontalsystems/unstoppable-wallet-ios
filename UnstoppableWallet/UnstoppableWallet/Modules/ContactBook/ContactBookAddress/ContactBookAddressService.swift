import Foundation
import RxSwift
import RxRelay
import MarketKit

class ContactBookAddressService {
    private let disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let addressService: AddressService
    private let contactBookManager: ContactBookManager
    private let currentContactUid: String?
    let mode: ContactBookAddressModule.Mode

    let unusedBlockchains: [Blockchain]
    let initialAddress: ContactAddress?

    private let selectedBlockchainRelay = PublishRelay<Blockchain>()
    var selectedBlockchain: Blockchain {
        didSet {
            selectedBlockchainRelay.accept(selectedBlockchain)
            addressService.change(blockchainType: selectedBlockchain.type)
            sync()
        }
    }

    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    var error: Error? {
        didSet {
            errorRelay.accept(error)
        }
    }

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: MarketKit.Kit, addressService: AddressService, contactBookManager: ContactBookManager, currentContactUid: String?, mode: ContactBookAddressModule.Mode, blockchain: Blockchain) {
        self.marketKit = marketKit
        self.addressService = addressService
        self.contactBookManager = contactBookManager
        self.currentContactUid = currentContactUid
        self.mode = mode

        let blockchainUids = BlockchainType.supported.map { $0.uid }
        let allBlockchains = ((try? marketKit.blockchains(uids: blockchainUids)) ?? []).sorted { $0.type.order < $1.type.order }

        switch mode {
        case .create(let addresses):
            let usedBlockchains = addresses.compactMap { try? marketKit.blockchain(uid: $0.blockchainUid) }
            unusedBlockchains = allBlockchains.filter { !usedBlockchains.contains($0) }
            initialAddress = nil
        case .edit(let address):
            unusedBlockchains = allBlockchains
            initialAddress = address
        }

        selectedBlockchain = blockchain

        addressService.customErrorService = self
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in
            self?.sync()
        }

        sync()
    }


    private func contact(with address: ContactAddress) -> Contact? {
        var otherContacts = contactBookManager.all
        if let contactUid = currentContactUid {
            otherContacts = otherContacts?.filter { contact in contact.uid != contactUid }
        }
        return otherContacts?.first { contact in
            contact.addresses.contains(address)
        }
    }

    private func sync() {
        switch addressService.state {
        case .empty:
            state = .idle
        case .loading:
            state = .loading
        case .validationError, .fetchError:
            state = .invalid(ValidationError.invalidAddress)
        case .success(let address):
            if let initialAddress, address.raw.lowercased() == initialAddress.address.lowercased() {
                state = .idle
                return
            }

            let address = ContactAddress(blockchainUid: selectedBlockchain.type.uid, address: address.raw)
            if let contact = contact(with: address) {

                let error = ValidationError.duplicate(contact: contact)
                self.error = error
                state = .invalid(error)

                return
            }
            state = .valid(address)
        }
        error = nil
    }

}

extension ContactBookAddressService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var selectedBlockchainObservable: Observable<Blockchain> {
        selectedBlockchainRelay.asObservable()
    }

}

extension ContactBookAddressService {

    enum State {
        case idle
        case loading
        case valid(ContactAddress)
        case invalid(Error)
    }

    enum ValidationError: Error {
        case invalidAddress
        case duplicate(contact: Contact)
    }

}

extension ContactBookAddressService: IErrorService {

    var errorObservable: Observable<Error?> {
        errorRelay.asObservable()
    }

}
