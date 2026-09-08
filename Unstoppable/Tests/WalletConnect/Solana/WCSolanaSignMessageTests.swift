import CryptoKit
import Foundation
import HsCryptoKit
import SolanaKit
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCSolanaSignMessageTests {
    private let client = WCSpySignClient()
    private let parser = WCSolanaSignMessageParser()

    private func request(message: String = "Sign in to Solana dApp", pubkey: String = SolanaRawSigningFixtures.ours) throws -> Request {
        try WCTestFixtures.request(method: WCSolanaSignMessagePayload.method, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", params: AnyCodable(any: ["message": HsCryptoKit.Base58.encode(Data(message.utf8)), "pubkey": pubkey]))
    }

    @Test func parsesBase58MessageAndPubkey() throws {
        let result = try parser.parse(request: request())
        let payload = try #require(result as? WCSolanaSignMessagePayload)

        #expect(payload.kind == .signMessage)
        #expect(payload.from == SolanaRawSigningFixtures.ours)
        #expect(payload.message == Data("Sign in to Solana dApp".utf8))
        #expect(payload.readableMessage == "Sign in to Solana dApp")
    }

    @Test func invalidPubkeyIsRejected() throws {
        let request = try request(pubkey: "not-a-key")
        #expect(throws: WCSolanaSignMessageParser.ParsingError.malformedParams) { try parser.parse(request: request) }
    }

    @Test func signsAndAnswersBase58Signature() async throws {
        let raw = try request()
        let parsed = try parser.parse(request: raw)
        let payload = try #require(parsed)
        let signer = try SolanaKit.Signer.instance(seed: SolanaRawSigningFixtures.seed)
        let handler = WCSolanaSignMessageHandler(signerProvider: StubSignerProvider(signer: signer), responder: WCResponder(signClient: client))

        try await handler.sign(request: WCRequest(payload: payload, verdict: .pass, dAppName: "dApp"))

        let call = try #require(client.calls.first)
        guard case let .response(value) = call.response else {
            Issue.record("expected response")
            return
        }
        let result = try value.get([String: String].self)
        let encoded = try #require(result["signature"])
        let signature = HsCryptoKit.Base58.decode(encoded)
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: SolanaRawSigningFixtures.oursPublicKey)
        #expect(publicKey.isValidSignature(signature, for: Data("Sign in to Solana dApp".utf8)))
    }
}

private final class StubSignerProvider: IWCSolanaSignerProvider {
    let signer: SolanaKit.Signer?

    init(signer: SolanaKit.Signer?) {
        self.signer = signer
    }
}
