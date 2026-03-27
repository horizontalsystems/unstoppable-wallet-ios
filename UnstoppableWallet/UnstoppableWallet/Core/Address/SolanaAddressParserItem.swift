import MarketKit
import RxSwift
import SolanaKit

class SolanaAddressParserItem: IAddressParserItem {
    var blockchainType: MarketKit.BlockchainType = .solana

    func handle(address: String) -> Single<Address> {
        do {
            _ = try SolanaKit.Address(address)
            return Single.just(Address(raw: address, blockchainType: blockchainType))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            _ = try SolanaKit.Address(address)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }
}
