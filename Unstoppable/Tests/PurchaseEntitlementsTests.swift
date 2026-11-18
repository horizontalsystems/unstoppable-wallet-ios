import Foundation
import Testing
@testable import WalletCore

struct PurchaseEntitlementsTests {
    private struct Entry: PurchaseEntitlement, Equatable {
        let id: UInt64
        let productID: String
        let purchaseDate: Date
        var revocationDate: Date?
    }

    private static let now = Date(timeIntervalSince1970: 1_000_000)
    private static let annual = "premium_1y"
    private static let lifetime = "premium_lifetime"

    private func entry(_ id: UInt64, _ productId: String = annual, purchased offset: TimeInterval, revoked: Bool = false) -> Entry {
        Entry(
            id: id,
            productID: productId,
            purchaseDate: Self.now.addingTimeInterval(offset),
            revocationDate: revoked ? Self.now : nil
        )
    }

    @Test func newerTransactionReplacesOlder() {
        let older = entry(1, purchased: -100)
        let newer = entry(2, purchased: -10)

        let applied = PurchaseEntitlements.applying(newer, to: [Self.annual: older])

        #expect(applied.recorded[Self.annual] == newer)
        #expect(!applied.cleared)
    }

    @Test func olderTransactionDoesNotReplaceNewer() {
        let older = entry(1, purchased: -100)
        let newer = entry(2, purchased: -10)

        let applied = PurchaseEntitlements.applying(older, to: [Self.annual: newer])

        #expect(applied.recorded[Self.annual] == newer)
    }

    @Test func sameDateTransactionReplacesRecorded() {
        let recorded = entry(1, purchased: -10)
        let incoming = entry(2, purchased: -10)

        let applied = PurchaseEntitlements.applying(incoming, to: [Self.annual: recorded])

        #expect(applied.recorded[Self.annual] == incoming)
    }

    @Test func revocationOfRecordedTransactionClearsIt() {
        let recorded = entry(1, purchased: -10)

        let applied = PurchaseEntitlements.applying(entry(1, purchased: -10, revoked: true), to: [Self.annual: recorded])

        #expect(applied.recorded[Self.annual] == nil)
        #expect(applied.cleared)
    }

    @Test func revocationOfOlderTransactionLeavesNewerEntry() {
        let newer = entry(2, purchased: -10)

        let applied = PurchaseEntitlements.applying(entry(1, purchased: -100, revoked: true), to: [Self.annual: newer])

        #expect(applied.recorded[Self.annual] == newer)
        #expect(!applied.cleared)
    }

    @Test func revocationOfUnrelatedTransactionLeavesEntry() {
        let recorded = entry(1, purchased: -100)

        let applied = PurchaseEntitlements.applying(entry(9, purchased: -10, revoked: true), to: [Self.annual: recorded])

        #expect(applied.recorded[Self.annual] == recorded)
        #expect(!applied.cleared)
    }

    @Test func revokedTransactionIsNeverRecorded() {
        let applied = PurchaseEntitlements.applying(entry(1, purchased: -10, revoked: true), to: [:])

        #expect(applied.recorded.isEmpty)
        #expect(!applied.cleared)
    }

    @Test func applyingLeavesOtherProductsAlone() {
        let lifetime = entry(1, Self.lifetime, purchased: -500)
        let annual = entry(2, purchased: -10)

        let applied = PurchaseEntitlements.applying(annual, to: [Self.lifetime: lifetime])

        #expect(applied.recorded == [Self.lifetime: lifetime, Self.annual: annual])
    }
}
