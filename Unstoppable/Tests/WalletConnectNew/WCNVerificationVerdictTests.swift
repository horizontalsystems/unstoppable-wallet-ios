import Testing
@testable import WalletCore

struct WCNVerificationVerdictTests {
    @Test func worstOfEmptyIsPass() {
        #expect(WCNVerificationVerdict.worst([]) == .pass)
    }

    @Test func worstPicksBlockOverCautionAndPass() {
        let verdict = WCNVerificationVerdict.worst([.pass, .block(reason: .originScam), .caution(reason: .originInvalid)])
        #expect(verdict == .block(reason: .originScam))
    }

    @Test func worstPicksCautionOverPass() {
        let verdict = WCNVerificationVerdict.worst([.pass, .caution(reason: .originInvalid), .pass])
        #expect(verdict == .caution(reason: .originInvalid))
    }

    @Test func worstKeepsFirstOfEqualSeverity() {
        let verdict = WCNVerificationVerdict.worst([.block(reason: .originScam), .block(reason: .missingSigner)])
        #expect(verdict == .block(reason: .originScam))
    }
}
