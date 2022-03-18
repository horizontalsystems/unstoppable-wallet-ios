import RxSwift
import EthereumKit

class EvmAddressParser: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        do {
            let address = try EthereumKit.Address(hex: address)
            return Single.just(Address(raw: address.hex))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        let address = try? EthereumKit.Address(hex: address)
        return Single.just(address != nil)
    }

}
