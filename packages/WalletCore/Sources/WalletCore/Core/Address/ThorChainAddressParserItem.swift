import MarketKit
import RxSwift
import ThorChainKit

final class ThorChainAddressParserItem: IAddressParserItem {
    let blockchainType: BlockchainType
    private let network: ThorChainKit.Network

    init(blockchainType: BlockchainType = .thorChain, network: ThorChainKit.Network = .mainnet) {
        self.blockchainType = blockchainType
        self.network = network
    }

    func handle(address: String) -> Single<Address> {
        do {
            _ = try ThorChainKit.Address(address, network: network)
            return Single.just(Address(raw: address, blockchainType: blockchainType))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            _ = try ThorChainKit.Address(address, network: network)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }
}
