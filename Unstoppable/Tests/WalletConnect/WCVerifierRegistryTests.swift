import Testing
@testable import WalletCore

struct WCVerifierRegistryTests {
    @Test func emptyRegistryPasses() throws {
        let registry = WCVerifierRegistry()
        let verdict = try registry.verify(WCTestFixtures.context())
        #expect(verdict == .pass)
    }

    @Test func onlyHandlingVerifiersRun() throws {
        let registry = WCVerifierRegistry()
        let skipped = StubVerifier(handles: false, verdict: .block(reason: .originScam))
        let active = StubVerifier(handles: true, verdict: .caution(reason: .originInvalid))
        registry.register(skipped)
        registry.register(active)

        let verdict = try registry.verify(WCTestFixtures.context())

        #expect(verdict == .caution(reason: .originInvalid))
        #expect(skipped.verifyCount == 0)
        #expect(active.verifyCount == 1)
    }

    @Test func worstVerdictWinsRegardlessOfOrder() throws {
        let registry = WCVerifierRegistry()
        registry.register(StubVerifier(handles: true, verdict: .caution(reason: .originInvalid)))
        registry.register(StubVerifier(handles: true, verdict: .block(reason: .originScam)))
        registry.register(StubVerifier(handles: true, verdict: .pass))

        let verdict = try registry.verify(WCTestFixtures.context())
        #expect(verdict == .block(reason: .originScam))
    }

    @Test func allHandlingVerifiersRunEvenAfterBlock() throws {
        let registry = WCVerifierRegistry()
        let first = StubVerifier(handles: true, verdict: .block(reason: .originScam))
        let second = StubVerifier(handles: true, verdict: .pass)
        registry.register(first)
        registry.register(second)

        _ = try registry.verify(WCTestFixtures.context())
        #expect(second.verifyCount == 1)
    }
}

private final class StubVerifier: IWCVerifier {
    private let handlesValue: Bool
    private let verdict: WCVerificationVerdict
    private(set) var verifyCount = 0

    init(handles: Bool, verdict: WCVerificationVerdict) {
        handlesValue = handles
        self.verdict = verdict
    }

    func handles(_: WCVerificationContext) -> Bool { handlesValue }

    func verify(_: WCVerificationContext) -> WCVerificationVerdict {
        verifyCount += 1
        return verdict
    }
}
