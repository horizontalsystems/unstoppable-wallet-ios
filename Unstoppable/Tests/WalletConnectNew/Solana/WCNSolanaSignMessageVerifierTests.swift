import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNSolanaSignMessageVerifierTests {
    private let verifier = WCNSolanaSignMessageVerifier()

    private func payload(message: Data) throws -> WCNSolanaSignMessagePayload {
        let request = try WCNTestFixtures.request(method: WCNSolanaSignMessagePayload.method, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")
        return WCNSolanaSignMessagePayload(request: request, publicKey: SolanaRawSigningFixtures.ours, message: message)
    }

    @Test func blocksMessageThatIsATransaction() throws {
        let context = try WCNTestFixtures.context(payload: payload(message: SolanaRawSigningFixtures.partiallySigned))
        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .block(reason: .solanaMessageIsTransaction))
    }

    @Test func passesPlainText() throws {
        let context = try WCNTestFixtures.context(payload: payload(message: Data("Sign in to dApp".utf8)))
        #expect(verifier.verify(context) == .pass)
    }

    @Test func ignoresOtherPayloads() throws {
        let context = try WCNTestFixtures.context()
        #expect(verifier.handles(context) == false)
    }
}
