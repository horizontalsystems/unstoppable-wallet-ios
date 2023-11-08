import RxSwift
import EvmKit
import MarketKit

class EvmAddressParser: IAddressParserItem {
    let blockchainType: BlockchainType

    init(blockchainType: BlockchainType = .ethereum) {
        self.blockchainType = blockchainType
    }

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
