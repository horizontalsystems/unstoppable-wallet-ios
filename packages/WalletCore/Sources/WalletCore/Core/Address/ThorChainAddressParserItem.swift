import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainAddressParserItem: IAddressParserItem {
    let blockchainType: BlockchainType = .thorChain

    func handle(address: String) -> Single<Address> {
        do {
            _ = try ThorChainKit.Address(address, network: .mainnet)
            return Single.just(Address(raw: address, blockchainType: blockchainType))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            _ = try ThorChainKit.Address(address, network: .mainnet)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }
}
