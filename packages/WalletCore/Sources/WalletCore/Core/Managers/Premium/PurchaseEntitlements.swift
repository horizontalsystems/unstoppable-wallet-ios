import Foundation
import StoreKit

/// The fields of a verified transaction that decide whether it is recorded as a purchase.
protocol PurchaseEntitlement {
    var id: UInt64 { get }
    var productID: String { get }
    var purchaseDate: Date { get }
    var revocationDate: Date? { get }
}

extension Transaction: PurchaseEntitlement {}

/// How `PurchaseManager` records verified transactions, kept free of StoreKit so it can be tested.
enum PurchaseEntitlements {
    /// Applies one verified transaction to the recorded purchases, keyed by product id. Recording only adds or
    /// updates; the one way an entry leaves is a revocation of that very transaction.
    ///
    /// - A revoked transaction is never recorded, and its id joins `revokedIds`. It clears the product's entry
    ///   only when it is the recorded transaction; a revoked older renewal or another grant leaves a newer valid
    ///   entry alone.
    /// - A transaction whose id is in `revokedIds` is never recorded, even when it arrives without its revocation
    ///   date: an entitlements snapshot taken before the revocation still holds the unrevoked copy.
    /// - An older transaction never replaces a newer one. At the same purchase date the incoming one wins.
    ///
    /// `cleared` is true when a revocation removed the entry, so the caller can look for another valid one.
    static func applying<T: PurchaseEntitlement>(
        _ incoming: T,
        to recorded: [String: T],
        revokedIds: Set<UInt64>
    ) -> (recorded: [String: T], revokedIds: Set<UInt64>, cleared: Bool) {
        var result = recorded
        let existing = recorded[incoming.productID]

        if incoming.revocationDate != nil {
            var revoked = revokedIds
            revoked.insert(incoming.id)

            guard let existing, existing.id == incoming.id else {
                return (result, revoked, false)
            }

            result[incoming.productID] = nil
            return (result, revoked, true)
        }

        if revokedIds.contains(incoming.id) {
            return (result, revokedIds, false)
        }

        if let existing, existing.purchaseDate > incoming.purchaseDate {
            return (result, revokedIds, false)
        }

        result[incoming.productID] = incoming
        return (result, revokedIds, false)
    }
}
