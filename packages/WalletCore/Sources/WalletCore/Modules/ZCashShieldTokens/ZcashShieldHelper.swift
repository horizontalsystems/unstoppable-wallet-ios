import Foundation

/// Transparent ZEC is spent only once shielded (spec 2026-10-14 §5.3). Pure, so it is tested without the
/// SDK: the wallet's balances and its newest shielding in, what a send or swap form offers out.
enum ZcashShieldHelper {
    /// A transfer proposal spends a shielding's output only once the shielding sits at or below the anchor, this
    /// many confirmations deep (the SDK's trusted policy); the wallet summary counts it earlier, by the
    /// transparent inputs' age (zcash_client_sqlite 0.22.0 wallet/common.rs: `t.block <= anchor_height`).
    static let anchorConfirmations = 3

    enum Step: Equatable {
        case shield
        case shielding(progress: Double)
        /// Private funds are confirming (an incoming note or the wallet's own change); nothing to shield.
        case confirming
    }

    static func shieldable(transparent: Decimal, threshold: Decimal) -> Decimal {
        transparent > threshold ? transparent : 0
    }

    /// Everything the user can spend now, after confirmations or after a shielding. Under the SDK's mask the
    /// cached available balance can exceed the total, hence the max.
    static func balance(available: Decimal, full: Decimal, transparent: Decimal, threshold: Decimal) -> Decimal {
        max(full, available) + shieldable(transparent: transparent, threshold: threshold)
    }

    /// What a transfer proposal can spend now: the available balance minus the part of a shielding's output the
    /// summary already counts while the shielding is not anchored yet (Android `shieldingHeldBack`).
    static func spendable(available: Decimal, full: Decimal, heldOutput: Decimal) -> Decimal {
        // the pending part of the output is not counted as available yet; never negative, even when a cached
        // available balance exceeds the total under the SDK's mask
        let pending = max(full - available, 0)
        let heldBack = min(max(heldOutput - pending, 0), available)
        return available - heldBack
    }

    /// The step `amount` needs: a running shielding is waited out; private funds still confirming are waited for
    /// when they cover the amount (the wallet's own change confirms in a few blocks, a shielding takes ten and a
    /// fee); only then the transparent funds are shielded. Nil when the spendable balance covers the amount or
    /// the whole balance does not.
    static func step(amount: Decimal, available: Decimal, full: Decimal, transparent: Decimal, threshold: Decimal, shieldingProgress: Double?, heldOutput: Decimal) -> Step? {
        let spendable = spendable(available: available, full: full, heldOutput: heldOutput)
        let balance = balance(available: available, full: full, transparent: transparent, threshold: threshold)

        guard amount > spendable, amount <= balance else {
            return nil
        }

        if let shieldingProgress {
            return .shielding(progress: shieldingProgress)
        }

        return amount <= max(full, available) ? .confirming : .shield
    }

    /// Confirmations of a transaction over the threshold, or nil once its output is spendable, when it failed, or
    /// before the first sync, when the chain height is unknown. Expired unmined transactions are dropped by the pool.
    static func progress(minedHeight: Int?, failed: Bool, lastBlockHeight: Int, confirmationsThreshold: Int) -> Double? {
        guard !failed, lastBlockHeight > 0 else {
            return nil
        }

        guard let minedHeight else {
            return 0
        }

        let confirmations = lastBlockHeight - minedHeight + 1
        guard confirmations < confirmationsThreshold else {
            return nil
        }

        return Double(max(0, confirmations)) / Double(confirmationsThreshold)
    }

    /// Whether a mined shielding is in the window where the summary may count its output but a proposal rejects it.
    static func isHeld(minedHeight: Int?, lastBlockHeight: Int) -> Bool {
        guard let minedHeight, lastBlockHeight > 0 else {
            return false
        }

        let confirmations = lastBlockHeight - minedHeight + 1
        return confirmations >= 1 && confirmations < anchorConfirmations
    }
}
