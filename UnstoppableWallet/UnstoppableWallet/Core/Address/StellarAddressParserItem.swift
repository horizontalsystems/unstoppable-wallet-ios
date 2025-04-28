import MarketKit
import RxSwift
import StellarKit

class StellarAddressParserItem: IAddressParserItem {
    var blockchainType: MarketKit.BlockchainType = .stellar

    func handle(address: String) -> Single<Address> {
        do {
            try StellarKit.Kit.validate(accountId: address)
            return Single.just(Address(raw: address, blockchainType: blockchainType))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            try StellarKit.Kit.validate(accountId: address)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }
}
