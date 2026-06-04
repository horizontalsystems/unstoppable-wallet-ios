import Foundation
import MarketKit

// Registry of OCP broadcasters; each app registers only what it ships.
class OpenCryptoPayBroadcasterFactory {
    private var types: [IOpenCryptoPayBroadcasterType.Type] = []

    func register(_ type: IOpenCryptoPayBroadcasterType.Type) {
        types.append(type)
    }

    func register(_ types: [IOpenCryptoPayBroadcasterType.Type]) {
        for type in types {
            self.types.append(type)
        }
    }

    // Union across registered types; first registered wins on method collision.
    var supportedChains: [String: BlockchainType] {
        types.reduce(into: [:]) { acc, type in
            acc.merge(type.supportedChains) { current, _ in current }
        }
    }

    func make(method: String, token: Token) -> IOpenCryptoPayBroadcaster? {
        types.lazy.compactMap { $0.make(method: method, token: token) }.first
    }
}

extension OpenCryptoPayBroadcasterFactory {
    static var unstoppable: OpenCryptoPayBroadcasterFactory {
        let factory = OpenCryptoPayBroadcasterFactory()
        factory.register([
            EvmHexBroadcaster.self,
            TronHashBroadcaster.self,
            BitcoinHexBroadcaster.self,
            SolanaHashBroadcaster.self,
            ZanoHashBroadcaster.self,
            MoneroHashBroadcaster.self,
        ])
        return factory
    }
}
