import Foundation
import MarketKit

enum OpenCryptoPayProof {
    case hex(String) // Type A — OCP server broadcasts.
    case tx(String) // Type B — we already broadcasted.
}

struct OpenCryptoPayBroadcastResult {
    let proof: OpenCryptoPayProof
    let transactionHash: String?
}

// Type A signs locally without broadcasting; Type B broadcasts and returns hash.
protocol IOpenCryptoPayBroadcaster {
    func broadcast(data: ISendData) async throws -> OpenCryptoPayBroadcastResult
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
protocol IOpenCryptoPayBroadcasterType {
    static var supportedChains: [String: BlockchainType] { get }
    static func make(method: String, token: Token) -> IOpenCryptoPayBroadcaster?
}
