import Foundation
import MarketKit
import MoneroKit
import RxSwift

class MoneroAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { .monero }

    func handle(address: String) -> Single<Address> {
        if MoneroKit.Kit.isValid(address: address, networkType: MoneroAdapter.networkType) {
            Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
        } else {
            Single.error(AddressService.AddressError.invalidAddress(blockchainName: "Monero"))
        }
    }

    func isValid(address: String) -> Single<Bool> {
        Single.just(MoneroKit.Kit.isValid(address: address, networkType: MoneroAdapter.networkType))
    }
}
