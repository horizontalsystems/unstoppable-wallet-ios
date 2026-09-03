import Foundation
import ReownWalletKit
import WalletConnectUtils
@testable import WalletCore

enum WCNTestFixtures {
    static let topic = "aa686b420fd4a0091c750575b8888c68405159ac0bb220fb34b334f48f9f2d3f"
    static let address = "0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d"

    static func request(method: String = "eth_sendTransaction", chainId: String = "eip155:1", params: AnyCodable = AnyCodable([String]())) throws -> Request {
        try Request(topic: topic, method: method, params: params, chainId: Blockchain(chainId)!)
    }

    static func parsed(method: String = "eth_sendTransaction", kind: WCNParsedRequest.Kind = .transaction, from: String? = address) throws -> WCNParsedRequest {
        try WCNParsedRequest(request: request(method: method), kind: kind, from: from)
    }

    static func context(parsed: WCNParsedRequest? = nil, verifyContext: VerifyContext? = nil, approvedAccounts: [WalletConnectUtils.Account] = []) throws -> WCNVerificationContext {
        try WCNVerificationContext(parsed: parsed ?? self.parsed(), verifyContext: verifyContext, accountId: "account-1", approvedAccounts: approvedAccounts)
    }
}

final class WCNSpySignClient: IWCNSignClient {
    struct Call: Equatable {
        let topic: String
        let requestId: RPCID
        let response: RPCResult
    }

    private(set) var calls = [Call]()
    var error: Error?

    func respond(topic: String, requestId: RPCID, response: RPCResult) async throws {
        if let error {
            throw error
        }
        calls.append(Call(topic: topic, requestId: requestId, response: response))
    }
}
