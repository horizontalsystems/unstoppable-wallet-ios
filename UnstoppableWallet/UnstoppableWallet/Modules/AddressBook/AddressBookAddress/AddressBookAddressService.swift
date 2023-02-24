//import Foundation
//import RxSwift
//import RxRelay
//import MarketKit
//
//class AddressBookAddressService {
//    private let disposeBag = DisposeBag()
//
//    private let marketKit: MarketKit.Kit
//    let usedTypes: [BlockchainType]
//    let currentAddress: ContactAddress?
//
//    var selectedType: BlockchainType
//    var address: String
//
//    private let stateRelay = BehaviorRelay<State>(value: .idle)
//    var state: State = .idle {
//        didSet {
//            stateRelay.accept(state)
//        }
//    }
//
//    private func blockchain(by address: ContactAddress) -> Blockchain? {
//        try? marketKit.blockchain(uid: address.blockchainUid)
//    }
//
//    init(marketKit: MarketKit.Kit, usedTypes: [BlockchainType], currentAddress: ContactAddress?) {
//        self.marketKit = marketKit
//        self.usedTypes = usedTypes
//        self.currentAddress = currentAddress
//
//        let currentType = currentAddress.flatMap { blockchain(by: $0)?.type }
//        selectedType = currentType ?? BlockchainType.supported[0]
//
//        restoreContainer()
//        sync()
//    }
//
//    private func restoreContainer() {
//        address = currentAddress?.address ?? ""
//    }
//
//    private func sync() {
//        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            state = .idle
//            return
//        }
//
//        let addresses = addresses.compactMap { address -> AddressItem? in
//            blockchain(by: address).map { AddressItem(blockchain: $0, address: address.address) }
//        }
//
//        if addresses.isEmpty {
//            state = .idle
//            return
//        }
//
//        state = .filled(Item(name: contactName, addresses: addresses))
//    }
//
//    private func syncAddresses() {
//        let usedBlockchainTypes = addresses.compactMap { blockchain(by: $0)?.type }
//
//        // check if all blockchains has adresses
//        allAddressesUsed = BlockchainType
//                   .supported
//                   .filter({ type in
//                       !usedBlockchainTypes.contains(type)
//                   }).count == 0
//    }
//
//}
//
//extension AddressBookAddressService {
//
//    var stateObservable: Observable<State> {
//        stateRelay.asObservable()
//    }
//
//    var allAddressesUsedObservable: Observable<Bool> {
//        allAddressesUsedRelay.asObservable()
//    }
//
//}
//
//extension AddressBookAddressService {
//
//    struct Item {
//        let type: BlockchainType
//        let address: String
//    }
//
//    enum State {
//        case idle
//        case valid(Item)
//        case invalid(Error)
//    }
//
//    enum ValidationError: Error {
//        case invalidAddress
//    }
//
//}
