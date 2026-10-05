import Foundation
import Testing
@testable import WalletCore

struct ZcashStallPolicyTests {
    private func action(attempt: Int, gaveUp: Bool, active: Bool = true, auto: Bool = true, rebuilds: Int = 0, requested: Bool = false) -> ZcashSyncService.StallAction {
        ZcashSyncService.stallAction(attempt: attempt, gaveUp: gaveUp, isActive: active, autoSelectEnabled: auto, rebuildsThisForeground: rebuilds, alreadyRequestedAutoSelect: requested)
    }

    @Test func firstAttemptIsIgnored() {
        #expect(action(attempt: 1, gaveUp: false) == .none)
    }

    @Test func secondAttemptRequestsAutoSelectOnce() {
        #expect(action(attempt: 2, gaveUp: false) == .requestAutoSelect)
        #expect(action(attempt: 3, gaveUp: false, requested: true) == .none)
        #expect(action(attempt: 2, gaveUp: false, auto: false) == .none)
    }

    @Test func gaveUpRebuildsWithinBudget() {
        #expect(action(attempt: 3, gaveUp: true, rebuilds: 0) == .rebuild)
        #expect(action(attempt: 1, gaveUp: true, rebuilds: 1) == .rebuild)
        #expect(action(attempt: 3, gaveUp: true, rebuilds: 2) == .terminal)
    }

    @Test func backgroundIgnoresEverything() {
        #expect(action(attempt: 3, gaveUp: true, active: false) == .none)
    }
}
