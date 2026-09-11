import Foundation
import Testing
@testable import WalletCore
import ZcashLightClientKit

struct ZcashSyncStateTests {
    private func snap(_ status: SyncStatus, masked: Bool = false, recovering: Bool = false, height: Int = 1000) -> ZcashSyncService.Snapshot {
        ZcashSyncService.Snapshot(syncStatus: status, isSpendableMasked: masked, isRecovering: recovering, latestHeight: height)
    }

    @Test func upToDateWithMaskShowsSyncingWithoutNumbers() {
        let mapped = ZcashSyncService.mapState(snap(.upToDate, masked: true), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: false)
        #expect(mapped.state == .syncing(progress: nil, remaining: nil, lastBlockDate: nil))
        #expect(mapped.effectiveSpendable == false)
    }

    @Test func upToDateWithoutMaskIsSyncedAndSpendable() {
        let mapped = ZcashSyncService.mapState(snap(.upToDate), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: false)
        #expect(mapped.state == .synced)
        #expect(mapped.effectiveSpendable == true)
    }

    @Test func syncingSpendableThenMaskedUpToDateClosesGate() {
        let first = ZcashSyncService.mapState(snap(.syncing(0.5, true)), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: false)
        #expect(first.effectiveSpendable == true)
        let second = ZcashSyncService.mapState(snap(.upToDate, masked: true), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: false)
        #expect(second.effectiveSpendable == false)
    }

    @Test func errorUnderMaskStaysNotSynced() {
        let mapped = ZcashSyncService.mapState(snap(.error(AppError.unknownError), masked: true), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: false)
        #expect(mapped.state.isNotSynced)
    }

    @Test func errorWhenStallTerminalKeepsStalledError() {
        let mapped = ZcashSyncService.mapState(snap(.error(AppError.unknownError)), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: true)
        guard case let .notSynced(error) = mapped.state, case AppError.zcash(reason: .syncStalled) = error else {
            Issue.record("expected syncStalled")
            return
        }
    }

    @Test func syncingWithoutProgressWhenStallTerminalKeepsStalledError() {
        let mapped = ZcashSyncService.mapState(snap(.syncing(0.5, false)), started: true, birthday: 100, lastBlockHeight: 1000, stallTerminal: true)
        guard case let .notSynced(error) = mapped.state, case AppError.zcash(reason: .syncStalled) = error else {
            Issue.record("expected syncStalled")
            return
        }
    }

    @Test func syncingProgressMapsRemainingFromBirthday() {
        let mapped = ZcashSyncService.mapState(snap(.syncing(0.5, false), height: 1000), started: true, birthday: 200, lastBlockHeight: 1000, stallTerminal: false)
        #expect(mapped.state == .syncing(progress: 50, remaining: 400, lastBlockDate: nil))
    }
}
