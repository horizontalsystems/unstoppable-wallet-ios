import Testing
@testable import WalletCore

struct WCNVerificationVerdictTests {
    @Test func worstOfEmptyIsPass() {
        #expect(WCNVerificationVerdict.worst([]) == .pass)
    }

    @Test func worstPicksBlockOverCautionAndPass() {
        let verdict = WCNVerificationVerdict.worst([.pass, .block(reason: "b"), .caution(reason: "c")])
        #expect(verdict == .block(reason: "b"))
    }

    @Test func worstPicksCautionOverPass() {
        let verdict = WCNVerificationVerdict.worst([.pass, .caution(reason: "c"), .pass])
        #expect(verdict == .caution(reason: "c"))
    }

    @Test func worstKeepsFirstOfEqualSeverity() {
        let verdict = WCNVerificationVerdict.worst([.block(reason: "first"), .block(reason: "second")])
        #expect(verdict == .block(reason: "first"))
    }
}
