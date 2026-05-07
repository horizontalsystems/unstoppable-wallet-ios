import Foundation
import MarketKit
import RxSwift
import ZanoKit

class ZanoAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { .zano }

    func handle(address: String) -> Single<Address> {
        if ZanoAdapter.isValidAddress(address) {
            Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
        } else {
            Single.error(AddressService.AddressError.invalidAddress(blockchainName: "Zano"))
        }
    }

    func isValid(address: String) -> Single<Bool> {
        Single.just(ZanoAdapter.isValidAddress(address))
    }
}
