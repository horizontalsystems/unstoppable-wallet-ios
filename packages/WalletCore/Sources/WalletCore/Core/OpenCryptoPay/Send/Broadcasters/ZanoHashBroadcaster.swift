import Foundation
import MarketKit

// Type B: broadcasts via ZanoKit, returns hash.
class ZanoHashBroadcaster: OpenCryptoPayBroadcaster {
    private let token: Token

    init(token: Token) {
        self.token = token
    }

    func broadcast(data: ISendData) async throws -> OpenCryptoPayProof {
        guard let zanoData = data as? ZanoSendHandler.SendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZanoAdapter else {
            throw OpenCryptoPayBroadcastError.noAdapter
        }
        let hash = try adapter.send(to: zanoData.address, amount: zanoData.amount, memo: zanoData.memo)
        return .tx(hash)
    }
}

extension ZanoHashBroadcaster: OpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = ["Zano": .zano]

    static func make(method: String, token: Token) -> OpenCryptoPayBroadcaster? {
        guard supportedChains.keys.contains(method) else { return nil }
        return ZanoHashBroadcaster(token: token)
    }
}
