import RxSwift
import EthereumKit

class EvmAddressParser: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        guard let address = try? EthereumKit.Address(hex: address) else {
            return Single.error(AddressService.AddressError.invalidAddress)
        }

        return Single.just(Address(raw: address.hex))
    }

    func isValid(address: String) -> Single<Bool> {
        let address = try? EthereumKit.Address(hex: address)
        return Single.just(address != nil)
    }

}
