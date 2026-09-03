import Foundation
import Testing
@testable import WalletCore

struct WCNEvmEthSignVerifierTests {
    private let verifier = WCNEvmEthSignVerifier()

    @Test func handlesOnlyEthSign() throws {
        let personal = try WCNStubRequestPayload.make(method: "personal_sign", kind: .signMessage)
        let ethSign = try WCNStubRequestPayload.make(method: "eth_sign", kind: .signMessage)

        let solanaEthSign = try WCNStubRequestPayload.make(method: "eth_sign", chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", kind: .signMessage)
        let personalContext = try WCNTestFixtures.context(payload: personal)
        let ethSignContext = try WCNTestFixtures.context(payload: ethSign)
        let solanaContext = try WCNTestFixtures.context(payload: solanaEthSign)

        #expect(verifier.handles(personalContext) == false)
        #expect(verifier.handles(ethSignContext))
        #expect(verifier.handles(solanaContext) == false)
    }

    @Test func blocksRaw32ByteHash() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_sign", kind: .signMessage)
        payload.stubMessage = Data(repeating: 0xAB, count: 32)

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .block(reason: .ethSignBlindHash))
    }

    @Test func cautionsNonTextMessage() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_sign", kind: .signMessage)
        payload.stubMessage = Data([0xFF, 0xFE, 0x00, 0x01, 0x02])

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .caution(reason: .ethSignUnreadable))
    }

    @Test func passesReadableText() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_sign", kind: .signMessage)
        payload.stubMessage = Data("Sign in to React App".utf8)

        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }

    @Test func passesMissingMessage() throws {
        let payload = try WCNStubRequestPayload.make(method: "eth_sign", kind: .signMessage)
        let verdict = try verifier.verify(WCNTestFixtures.context(payload: payload))
        #expect(verdict == .pass)
    }
}
