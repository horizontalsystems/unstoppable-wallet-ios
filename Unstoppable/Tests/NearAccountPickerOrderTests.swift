import BigInt
import Foundation
import NearKit
import Testing
@testable import WalletCore

/// Spec 2026-10-13 §6.3: order own named → shared named → own implicit → lost implicit, richest first in each;
/// default own named → own implicit → shared named → lost implicit. Full-access keys only, as Android.
struct NearAccountPickerOrderTests {
    private typealias Account = NearAccountPickerViewModel.Account

    private static func named(_ id: String, near: Int, otherFullKeys: Bool? = false, contract: Bool? = false) -> Account {
        Account(accountId: id, isImplicit: false, available: BigUInt(near), hasContract: contract, accessLost: false, otherFullAccessKeys: otherFullKeys)
    }

    private static func implicit(near: Int, lost: Bool = false) -> Account {
        Account(accountId: "implicit", isImplicit: true, available: BigUInt(near), hasContract: false, accessLost: lost, otherFullAccessKeys: lost)
    }

    private func order(_ accounts: [Account]) -> [String] {
        NearAccountPickerViewModel.ordered(accounts).map(\.accountId)
    }

    /// the public "abandon … about" phrase: two named accounts with only function-call keys of others, a lost implicit
    @Test func publicTestPhrase() {
        let accounts = [Self.implicit(near: 311, lost: true), Self.named("yuheshui.near", near: 197), Self.named("yattsta12.near", near: 210)]

        #expect(order(accounts) == ["yattsta12.near", "yuheshui.near", "implicit"])
        #expect(NearAccountPickerViewModel.preselected(accounts) == "yattsta12.near")
    }

    /// a stranger who added the phrase's key to a funded account of theirs does not become the default
    @Test func poisonedAccountIsNotTheDefault() {
        let accounts = [Self.implicit(near: 0), Self.named("trap.near", near: 1000, otherFullKeys: true)]

        #expect(order(accounts) == ["trap.near", "implicit"])
        #expect(NearAccountPickerViewModel.preselected(accounts) == "implicit")
    }

    @Test func ownNamedAccountIsTheDefault() {
        let accounts = [Self.implicit(near: 50), Self.named("shared.near", near: 900, otherFullKeys: true), Self.named("alice.near", near: 10)]

        #expect(order(accounts) == ["alice.near", "shared.near", "implicit"])
        #expect(NearAccountPickerViewModel.preselected(accounts) == "alice.near")
    }

    /// a contract or unknown details make a named account shared
    @Test func contractOrUnknownDetailsAreShared() {
        let contract = Self.named("dapp.near", near: 5, contract: true)
        let unknown = Self.named("unknown.near", near: 5, otherFullKeys: nil)

        #expect(NearAccountPickerViewModel.group(contract) == .namedShared)
        #expect(NearAccountPickerViewModel.group(unknown) == .namedShared)
    }

    /// with the implicit account lost, a shared named account is preferred over it
    @Test func sharedNamedBeforeLostImplicit() {
        let accounts = [Self.implicit(near: 300, lost: true), Self.named("migrated.near", near: 1, otherFullKeys: true)]

        #expect(order(accounts) == ["migrated.near", "implicit"])
        #expect(NearAccountPickerViewModel.preselected(accounts) == "migrated.near")
    }

    @Test func lostImplicitAloneIsStillSelectable() {
        #expect(NearAccountPickerViewModel.preselected([Self.implicit(near: 0, lost: true)]) == "implicit")
    }
}
