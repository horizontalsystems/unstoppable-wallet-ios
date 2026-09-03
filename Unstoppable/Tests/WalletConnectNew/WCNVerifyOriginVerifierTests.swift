import ReownWalletKit
import Testing
@testable import WalletCore

struct WCNVerifyOriginVerifierTests {
    private let verifier = WCNVerifyOriginVerifier()

    @Test func blocksScam() throws {
        let context = try WCNTestFixtures.context(verifyContext: VerifyContext(origin: "https://evil.example", validation: .scam))
        #expect(verifier.verify(context) == .block(reason: "Origin is flagged as scam"))
    }

    @Test func cautionsInvalid() throws {
        let context = try WCNTestFixtures.context(verifyContext: VerifyContext(origin: "https://mismatch.example", validation: .invalid))
        #expect(verifier.verify(context) == .caution(reason: "Origin does not match the verified domain"))
    }

    @Test func passesValidUnknownAndMissing() throws {
        let valid = try WCNTestFixtures.context(verifyContext: VerifyContext(origin: "https://react-app.walletconnect.com", validation: .valid))
        let unknown = try WCNTestFixtures.context(verifyContext: VerifyContext(origin: nil, validation: .unknown))
        let missing = try WCNTestFixtures.context(verifyContext: nil)

        #expect(verifier.verify(valid) == .pass)
        #expect(verifier.verify(unknown) == .pass)
        #expect(verifier.verify(missing) == .pass)
    }
}
