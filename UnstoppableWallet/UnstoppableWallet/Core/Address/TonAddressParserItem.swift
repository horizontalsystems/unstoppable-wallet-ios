import MarketKit
import RxSwift
import TonKitKmm

class TonAddressParserItem: IAddressParserItem {
    var blockchainType: MarketKit.BlockchainType = .ton

    func handle(address: String) -> Single<Address> {
        do {
            try TonKit.companion.validate(address: address)
            return Single.just(Address(raw: address, blockchainType: blockchainType))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            try TonKit.companion.validate(address: address)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }
}
