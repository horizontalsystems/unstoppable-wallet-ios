import Foundation
import Testing
@testable import WalletCore
import ZcashLightClientKit

struct ZcashBalanceComposeTests {
    private func inputs(shieldedTotal: Int64, spendable: Int64, unshielded: Int64 = 0, awaiting: Int64 = 0, orchard: Int64 = 0) -> ZcashBalanceService.Inputs {
        .init(shieldedTotal: Zatoshi(shieldedTotal), shieldedSpendable: Zatoshi(spendable), unshielded: Zatoshi(unshielded), awaitingResolution: Zatoshi(awaiting), orchardSpendable: Zatoshi(orchard))
    }

    private let previous = ZcashBalanceData(id: "w", full: 3, available: 2, transparent: 1, orchard: 0)

    @Test func unmaskedTakesVisibleSpendableAndLocalTotals() {
        let local = inputs(shieldedTotal: 500_000_000, spendable: 400_000_000, unshielded: 200_000_000)
        let visible = inputs(shieldedTotal: 500_000_000, spendable: 400_000_000, unshielded: 200_000_000)
        let data = ZcashBalanceService.compose(id: "w", local: local, visible: visible, isSpendableMasked: false, isRecovering: false, previous: previous)
        #expect(data.full == 5)
        #expect(data.transparent == 2)
        #expect(data.available == 4)
        #expect(data.balanceData.total == 7)
    }

    @Test func maskedKeepsPreviousAvailableAndFoldsAwaitingIntoTransparent() {
        let local = inputs(shieldedTotal: 500_000_000, spendable: 400_000_000, unshielded: 200_000_000)
        let visible = inputs(shieldedTotal: 500_000_000, spendable: 0, unshielded: 0, awaiting: 200_000_000)
        let data = ZcashBalanceService.compose(id: "w", local: local, visible: visible, isSpendableMasked: true, isRecovering: false, previous: previous)
        #expect(data.available == 2) // previous, never the masked zero
        #expect(data.transparent == 2) // unshielded + awaitingResolution
        #expect(data.balanceData.total == 7)
    }

    @Test func recoveringUsesVisibleTotalsAndKeepsPreviousAvailable() {
        let local = inputs(shieldedTotal: 900_000_000, spendable: 900_000_000) // provisional, inflated
        let visible = inputs(shieldedTotal: 500_000_000, spendable: 500_000_000) // reconciled net, surfaced as "spendable"
        let data = ZcashBalanceService.compose(id: "w", local: local, visible: visible, isSpendableMasked: false, isRecovering: true, previous: previous)
        #expect(data.full == 5)
        #expect(data.available == 2) // previous, never the recovery headline
    }

    @Test func missingLocalFallsBackToVisible() {
        let visible = inputs(shieldedTotal: 500_000_000, spendable: 100_000_000, unshielded: 50_000_000)
        let data = ZcashBalanceService.compose(id: "w", local: nil, visible: visible, isSpendableMasked: false, isRecovering: false, previous: previous)
        #expect(data.full == 5)
        #expect(data.transparent == 0.5)
    }
}
