import Foundation
import MarketKit

// Type B: broadcasts via MoneroKit, returns txID.
class MoneroHashBroadcaster: IOpenCryptoPayBroadcaster {
    private let token: Token

    init(token: Token) {
        self.token = token
    }

    func broadcast(data: ISendData) async throws -> OpenCryptoPayBroadcastResult {
        guard let moneroData = data as? MoneroSendHandler.SendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? MoneroAdapter else {
            throw OpenCryptoPayBroadcastError.noAdapter
        }
        let hashes = try adapter.send(
            to: moneroData.address,
            amount: moneroData.amount,
            priority: moneroData.priority,
            memo: moneroData.memo
        )
        guard let hash = hashes.first else {
            throw OpenCryptoPayBroadcastError.missingTxId
        }
        return .init(proof: .tx(hash), transactionHash: hash)
    }
}

extension MoneroHashBroadcaster: IOpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = ["Monero": .monero]

    static func make(method: String, token: Token) -> IOpenCryptoPayBroadcaster? {
        guard supportedChains.keys.contains(method) else { return nil }
        return MoneroHashBroadcaster(token: token)
    }
}
