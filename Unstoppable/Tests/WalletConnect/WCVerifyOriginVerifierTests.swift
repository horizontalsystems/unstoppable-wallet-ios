import ReownWalletKit
import Testing
@testable import WalletCore

struct WCVerifyOriginVerifierTests {
    private let verifier = WCVerifyOriginVerifier()

    @Test func blocksScam() throws {
        let context = try WCTestFixtures.context(verifyContext: VerifyContext(origin: "https://evil.example", validation: .scam))
        #expect(verifier.verify(context) == .block(reason: .originScam))
    }

    @Test func cautionsInvalid() throws {
        let context = try WCTestFixtures.context(verifyContext: VerifyContext(origin: "https://mismatch.example", validation: .invalid))
        #expect(verifier.verify(context) == .caution(reason: .originInvalid))
    }

    @Test func passesValidUnknownAndMissing() throws {
        let valid = try WCTestFixtures.context(verifyContext: VerifyContext(origin: "https://react-app.walletconnect.com", validation: .valid))
        let unknown = try WCTestFixtures.context(verifyContext: VerifyContext(origin: nil, validation: .unknown))
        let missing = try WCTestFixtures.context(verifyContext: nil)

        #expect(verifier.verify(valid) == .pass)
        #expect(verifier.verify(unknown) == .pass)
        #expect(verifier.verify(missing) == .pass)
    }
}
