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
    /// - A revoked transaction is never recorded. It clears the product's entry only when it is the recorded
    ///   transaction; a revoked older renewal or another grant leaves a newer valid entry alone.
    /// - An older transaction never replaces a newer one. At the same purchase date the incoming one wins.
    ///
    /// `cleared` is true when a revocation removed the entry, so the caller can look for another valid one.
    static func applying<T: PurchaseEntitlement>(_ incoming: T, to recorded: [String: T]) -> (recorded: [String: T], cleared: Bool) {
        var result = recorded
        let existing = recorded[incoming.productID]

        if incoming.revocationDate != nil {
            guard let existing, existing.id == incoming.id else {
                return (result, false)
            }

            result[incoming.productID] = nil
            return (result, true)
        }

        if let existing, existing.purchaseDate > incoming.purchaseDate {
            return (result, false)
        }

        result[incoming.productID] = incoming
        return (result, false)
    }
}
