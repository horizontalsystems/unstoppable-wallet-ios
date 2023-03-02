import Foundation
import RxSwift
import RxRelay
import MarketKit

class AddressBookAddressService {
    private let disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let addressService: AddressService
    let mode: AddressBookAddressModule.Mode

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

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    private func blockchain(by address: ContactAddress) -> Blockchain? {
        try? marketKit.blockchain(uid: address.blockchainUid)
    }

    init(marketKit: MarketKit.Kit, addressService: AddressService, mode: AddressBookAddressModule.Mode, blockchain: Blockchain) {
        self.marketKit = marketKit
        self.addressService = addressService
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

        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in
            self?.sync()
        }

        sync()
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
            if let initialAddress, address.raw == initialAddress.address {
                state = .idle
                return
            }
            state = .valid(ContactAddress(blockchainUid: selectedBlockchain.type.uid, address: address.raw))
        }
    }

}

extension AddressBookAddressService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var selectedBlockchainObservable: Observable<Blockchain> {
        selectedBlockchainRelay.asObservable()
    }

}

extension AddressBookAddressService {

    enum State {
        case idle
        case loading
        case valid(ContactAddress)
        case invalid(Error)
    }

    enum ValidationError: Error {
        case invalidAddress
    }

}
