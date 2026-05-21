import Foundation
import MarketKit

// Type A: signs UTXO tx locally, returns hex; OCP server broadcasts.
class BitcoinHexBroadcaster: OpenCryptoPayBroadcaster {
    private let token: Token

    init(token: Token) {
        self.token = token
    }

    func broadcast(data: ISendData) async throws -> OpenCryptoPayProof {
        guard let btcData = data as? BitcoinSendHandler.SendData else {
            throw OpenCryptoPayBroadcastError.dataMismatch
        }
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? BitcoinBaseAdapter else {
            throw OpenCryptoPayBroadcastError.noAdapter
        }
        let raw = try adapter.signedRawHex(params: btcData.params)
        return .hex(raw.hs.hexString)
    }
}

extension BitcoinHexBroadcaster: OpenCryptoPayBroadcasterType {
    static let supportedChains: [String: BlockchainType] = ["Bitcoin": .bitcoin]

    static func make(method: String, token: Token) -> OpenCryptoPayBroadcaster? {
        guard supportedChains.keys.contains(method) else { return nil }
        return BitcoinHexBroadcaster(token: token)
    }
}
