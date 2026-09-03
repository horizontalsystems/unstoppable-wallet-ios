import Testing
@testable import WalletCore

struct WCNVerifierRegistryTests {
    @Test func emptyRegistryPasses() throws {
        let registry = WCNVerifierRegistry()
        let verdict = try registry.verify(WCNTestFixtures.context())
        #expect(verdict == .pass)
    }

    @Test func onlyHandlingVerifiersRun() throws {
        let registry = WCNVerifierRegistry()
        let skipped = StubVerifier(handles: false, verdict: .block(reason: "skipped"))
        let active = StubVerifier(handles: true, verdict: .caution(reason: "active"))
        registry.register(skipped)
        registry.register(active)

        let verdict = try registry.verify(WCNTestFixtures.context())

        #expect(verdict == .caution(reason: "active"))
        #expect(skipped.verifyCount == 0)
        #expect(active.verifyCount == 1)
    }

    @Test func worstVerdictWinsRegardlessOfOrder() throws {
        let registry = WCNVerifierRegistry()
        registry.register(StubVerifier(handles: true, verdict: .caution(reason: "c")))
        registry.register(StubVerifier(handles: true, verdict: .block(reason: "b")))
        registry.register(StubVerifier(handles: true, verdict: .pass))

        let verdict = try registry.verify(WCNTestFixtures.context())
        #expect(verdict == .block(reason: "b"))
    }

    @Test func allHandlingVerifiersRunEvenAfterBlock() throws {
        let registry = WCNVerifierRegistry()
        let first = StubVerifier(handles: true, verdict: .block(reason: "b"))
        let second = StubVerifier(handles: true, verdict: .pass)
        registry.register(first)
        registry.register(second)

        _ = try registry.verify(WCNTestFixtures.context())
        #expect(second.verifyCount == 1)
    }
}

private final class StubVerifier: IWCNVerifier {
    private let handlesValue: Bool
    private let verdict: WCNVerificationVerdict
    private(set) var verifyCount = 0

    init(handles: Bool, verdict: WCNVerificationVerdict) {
        handlesValue = handles
        self.verdict = verdict
    }

    func handles(_: WCNVerificationContext) -> Bool { handlesValue }

    func verify(_: WCNVerificationContext) -> WCNVerificationVerdict {
        verifyCount += 1
        return verdict
    }
}
