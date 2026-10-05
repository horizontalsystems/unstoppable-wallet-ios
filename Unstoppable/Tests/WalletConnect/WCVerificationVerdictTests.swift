import Testing
@testable import WalletCore

struct WCVerificationVerdictTests {
    @Test func worstOfEmptyIsPass() {
        #expect(WCVerificationVerdict.worst([]) == .pass)
    }

    @Test func worstPicksBlockOverCautionAndPass() {
        let verdict = WCVerificationVerdict.worst([.pass, .block(reason: .originScam), .caution(reason: .originInvalid)])
        #expect(verdict == .block(reason: .originScam))
    }

    @Test func worstPicksCautionOverPass() {
        let verdict = WCVerificationVerdict.worst([.pass, .caution(reason: .originInvalid), .pass])
        #expect(verdict == .caution(reason: .originInvalid))
    }

    @Test func worstKeepsFirstOfEqualSeverity() {
        let verdict = WCVerificationVerdict.worst([.block(reason: .originScam), .block(reason: .missingSigner)])
        #expect(verdict == .block(reason: .originScam))
    }
}
