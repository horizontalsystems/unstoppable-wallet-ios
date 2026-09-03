import Foundation
import Testing
@testable import WalletCore

struct WCNEvmEthSignVerifierTests {
    private let verifier = WCNEvmEthSignVerifier()

    @Test func handlesOnlyEthSign() throws {
        let personal = try WCNStubParsedRequest.make(method: "personal_sign", kind: .signMessage)
        let ethSign = try WCNStubParsedRequest.make(method: "eth_sign", kind: .signMessage)

        let solanaEthSign = try WCNStubParsedRequest.make(method: "eth_sign", chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", kind: .signMessage)
        let personalContext = try WCNTestFixtures.context(parsed: personal)
        let ethSignContext = try WCNTestFixtures.context(parsed: ethSign)
        let solanaContext = try WCNTestFixtures.context(parsed: solanaEthSign)

        #expect(verifier.handles(personalContext) == false)
        #expect(verifier.handles(ethSignContext))
        #expect(verifier.handles(solanaContext) == false)
    }

    @Test func blocksRaw32ByteHash() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_sign", kind: .signMessage)
        parsed.stubMessage = Data(repeating: 0xAB, count: 32)

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .block(reason: "eth_sign over a raw 32-byte hash is blind signing"))
    }

    @Test func cautionsNonTextMessage() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_sign", kind: .signMessage)
        parsed.stubMessage = Data([0xFF, 0xFE, 0x00, 0x01, 0x02])

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .caution(reason: "eth_sign message is not readable text"))
    }

    @Test func passesReadableText() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_sign", kind: .signMessage)
        parsed.stubMessage = Data("Sign in to React App".utf8)

        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .pass)
    }

    @Test func passesMissingMessage() throws {
        let parsed = try WCNStubParsedRequest.make(method: "eth_sign", kind: .signMessage)
        let verdict = try verifier.verify(WCNTestFixtures.context(parsed: parsed))
        #expect(verdict == .pass)
    }
}
