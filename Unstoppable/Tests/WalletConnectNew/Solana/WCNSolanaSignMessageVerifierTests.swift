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

    // the bytes a signer actually signs: the transaction without its signatures section
    @Test func blocksBareCompiledMessage() throws {
        let context = try WCNTestFixtures.context(payload: payload(message: SolanaRawSigningFixtures.partiallySigned.dropFirst(129)))
        #expect(verifier.verify(context) == .block(reason: .solanaMessageIsTransaction))
    }

    @Test func cautionsNonTextMessage() throws {
        let context = try WCNTestFixtures.context(payload: payload(message: Data([0xFF, 0xFE, 0x00, 0x01, 0x02])))
        #expect(verifier.verify(context) == .caution(reason: .solanaMessageUnreadable))
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
