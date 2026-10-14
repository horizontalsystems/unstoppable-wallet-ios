import Foundation
import Testing
@testable import WalletCore

// Spec 2026-10-14 §5.3: a form's balance is everything the user will be able to spend; the step bridges the
// spendable part and the rest: Shielding in flight → Shield the transparent funds → Confirming private funds.
struct ZcashShieldStepTests {
    private typealias Helper = ZcashShieldHelper

    private let threshold = ZcashAdapter.minimalThreshold

    private func step(amount: Decimal, available: Decimal, full: Decimal? = nil, transparent: Decimal = 0, shieldingProgress: Double? = nil, heldOutput: Decimal = 0) -> Helper.Step? {
        Helper.step(amount: amount, available: available, full: full ?? available, transparent: transparent, threshold: threshold, shieldingProgress: shieldingProgress, heldOutput: heldOutput)
    }

    private func balance(available: Decimal, full: Decimal? = nil, transparent: Decimal = 0) -> Decimal {
        Helper.balance(available: available, full: full ?? available, transparent: transparent, threshold: threshold)
    }

    // MARK: Shield

    @Test func amountWithinSpendableNeedsNoStep() {
        #expect(step(amount: 2, available: 2, transparent: 5) == nil)
    }

    @Test func amountJustAboveSpendableOffersShield() {
        #expect(step(amount: 2.00000001, available: 2, transparent: 5) == .shield)
    }

    @Test func amountEqualToBalanceOffersShield() {
        #expect(step(amount: 7, available: 2, transparent: 5) == .shield)
    }

    @Test func amountJustAboveBalanceIsInsufficient() {
        #expect(step(amount: 7.00000001, available: 2, transparent: 5) == nil)
    }

    @Test func transparentAtThresholdOffersNothing() {
        #expect(step(amount: 2.0001, available: 2, transparent: threshold) == nil)
        #expect(balance(available: 2, transparent: threshold) == 2)
    }

    @Test func transparentJustAboveThresholdOffersShield() {
        let transparent = threshold + 0.00000001
        #expect(step(amount: 2.0001, available: 2, transparent: transparent) == .shield)
        #expect(balance(available: 2, transparent: transparent) == 2 + transparent)
    }

    @Test func onlyTransparentOffersShield() {
        #expect(step(amount: 3, available: 0, transparent: 5) == .shield)
        #expect(balance(available: 0, transparent: 5) == 5)
    }

    // MARK: Confirming

    @Test func unconfirmedPrivateFundsWaitForConfirmation() {
        #expect(step(amount: 3, available: 2, full: 4) == .confirming)
    }

    @Test func amountEqualToBalanceWaitsForConfirmation() {
        #expect(step(amount: 4, available: 2, full: 4) == .confirming)
    }

    // the wallet's own change right after a send
    @Test func changeAfterSendWaitsForConfirmation() {
        #expect(step(amount: 1, available: 0, full: 3.9998) == .confirming)
    }

    // both waits run in parallel: shielding is offered while other funds confirm
    @Test func shieldOfferedWhileOtherFundsConfirm() {
        #expect(step(amount: 7.5, available: 2, full: 3, transparent: 5) == .shield)
    }

    // MARK: Shielding in flight

    @Test func sentShieldingBeforeRecordShowsZeroProgress() {
        #expect(step(amount: 3, available: 2, transparent: 5, shieldingProgress: 0) == .shielding(progress: 0))
    }

    @Test func shieldingTakesPrecedenceOverNewTransparent() {
        #expect(step(amount: 3, available: 2, full: 7, transparent: 1, shieldingProgress: 0.4) == .shielding(progress: 0.4))
    }

    @Test func shieldingWithinSpendableNeedsNoStep() {
        #expect(step(amount: 2, available: 2, full: 7, shieldingProgress: 0.4) == nil)
    }

    @Test func shieldingAboveBalanceIsInsufficient() {
        #expect(step(amount: 7.1, available: 2, full: 7, shieldingProgress: 0.4) == nil)
    }

    // MARK: Held-back output (SDK anchor trap)

    @Test func heldBackIsZeroWithoutHeldOutput() {
        #expect(Helper.spendable(available: 7, full: 7, heldOutput: 0) == 7)
    }

    @Test func heldBackIsZeroWhileOutputPending() {
        #expect(Helper.spendable(available: 2, full: 7, heldOutput: 5) == 2)
    }

    @Test func heldBackLimitsSpendableOnceSummaryCountsOutput() {
        #expect(Helper.spendable(available: 7, full: 7, heldOutput: 5) == 2)
        #expect(step(amount: 3, available: 7, full: 7, shieldingProgress: 0.1, heldOutput: 5) == .shielding(progress: 0.1))
    }

    @Test func heldBackNeverExceedsAvailable() {
        #expect(Helper.spendable(available: 1, full: 1, heldOutput: 5) == 0)
    }

    @Test func balanceStaysStableWithHeldBack() {
        #expect(balance(available: 7, full: 7) == 7)
        #expect(balance(available: 2, full: 7) == 7)
    }

    // under the SDK's mask the cached available balance can exceed the total
    @Test func staleAvailableAboveFullKeepsBalanceAtAvailable() {
        #expect(balance(available: 3, full: 2) == 3)
        #expect(step(amount: 3, available: 3, full: 2) == nil)
    }

    // MARK: Progress

    @Test func unknownHeightIsNotInFlight() {
        #expect(Helper.progress(minedHeight: nil, failed: false, lastBlockHeight: 0, confirmationsThreshold: 10) == nil)
        #expect(Helper.progress(minedHeight: 100, failed: false, lastBlockHeight: 0, confirmationsThreshold: 10) == nil)
    }

    @Test func failedShieldingIsNotInFlight() {
        #expect(Helper.progress(minedHeight: nil, failed: true, lastBlockHeight: 100, confirmationsThreshold: 10) == nil)
    }

    @Test func unminedIsZeroProgress() {
        #expect(Helper.progress(minedHeight: nil, failed: false, lastBlockHeight: 100, confirmationsThreshold: 10) == 0)
    }

    @Test func minedAboveLastBlockIsZeroProgress() {
        #expect(Helper.progress(minedHeight: 105, failed: false, lastBlockHeight: 100, confirmationsThreshold: 10) == 0)
    }

    @Test func ninthConfirmationIsStillInFlight() {
        #expect(Helper.progress(minedHeight: 100, failed: false, lastBlockHeight: 108, confirmationsThreshold: 10) == 0.9)
    }

    @Test func tenthConfirmationEndsShielding() {
        #expect(Helper.progress(minedHeight: 100, failed: false, lastBlockHeight: 109, confirmationsThreshold: 10) == nil)
    }

    @Test func confirmationsRoundTripForEveryStep() {
        for confirmations in 0 ..< 10 {
            let progress = Helper.progress(minedHeight: 100, failed: false, lastBlockHeight: 99 + confirmations, confirmationsThreshold: 10)
            #expect(progress.map { Helper.confirmations(progress: $0, threshold: 10) } == confirmations)
        }
    }

    // MARK: Anchoring

    @Test func anchoringCoversFirstTwoConfirmationsOnly() {
        #expect(!Helper.isAnchoring(minedHeight: nil, lastBlockHeight: 100))
        #expect(Helper.isAnchoring(minedHeight: 100, lastBlockHeight: 100))
        #expect(Helper.isAnchoring(minedHeight: 100, lastBlockHeight: 101))
        #expect(!Helper.isAnchoring(minedHeight: 100, lastBlockHeight: 102))
        #expect(!Helper.isAnchoring(minedHeight: 100, lastBlockHeight: 0))
    }
}
