import RxSwift
import TronKit
import MarketKit

class TronAddressParser: IAddressParserItem {
    var blockchainType: BlockchainType { .tron }

    func handle(address: String) -> Single<Address> {
        do {
            let address = try TronKit.Address(address: address)
            return Single.just(Address(raw: address.base58))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        let address = try? TronKit.Address(address: address)
        return Single.just(address != nil)
    }

}
