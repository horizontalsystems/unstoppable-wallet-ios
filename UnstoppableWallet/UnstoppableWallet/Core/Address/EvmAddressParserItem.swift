import RxSwift
import EvmKit

class EvmAddressParser: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        do {
            let address = try EvmKit.Address(hex: address)
            return Single.just(Address(raw: address.hex))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        let address = try? EvmKit.Address(hex: address)
        return Single.just(address != nil)
    }

}
