import Foundation
import MarketKit

enum OpenCryptoPayProof {
    case hex(String) // Type A — OCP server broadcasts.
    case tx(String) // Type B — we already broadcasted.
}

// Type A signs locally without broadcasting; Type B broadcasts and returns hash.
protocol OpenCryptoPayBroadcaster {
    func broadcast(data: ISendData) async throws -> OpenCryptoPayProof
}

enum OpenCryptoPayBroadcastError: Error {
    case dataMismatch
    case noAdapter
    case noWrapper
    case noSigner
    case missingField(String)
    case missingTxId
}

// Self-registration: each broadcaster declares supported methods + how to build itself.
protocol OpenCryptoPayBroadcasterType {
    static var supportedChains: [String: BlockchainType] { get }
    static func make(method: String, token: Token) -> OpenCryptoPayBroadcaster?
}
