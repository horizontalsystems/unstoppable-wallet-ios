import Foundation
import MarketKit
import Testing
@testable import WalletCore
import XrpKit

/// The gates that need the ledger's answer about the recipient. They live on the confirmation, not
/// on the send form, and an unanswered lookup blocks the send there (Android
/// `SendTransactionServiceXrp.cautions`).
struct XrpDestinationGateTests {
    @Test func unfundedDestinationBelowBaseReserveIsRefused() async {
        let adapter = StubSendXrpAdapter(exists: false)

        // one drop short of the reserve
        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.xrpToken, amount: adapter.baseReserve - Decimal(string: "0.000001")!, address: Self.destination, destinationTag: nil)

        guard case let .belowMinimumFirstDeposit(minimum) = error as? XrpSendHelper.TransactionError else {
            Issue.record("expected a minimum first deposit error, got \(String(describing: error))")
            return
        }
        #expect(minimum == adapter.baseReserve)
    }

    // the ledger creates the account from the base reserve upwards, the boundary included
    @Test func unfundedDestinationAtBaseReservePasses() async {
        let adapter = StubSendXrpAdapter(exists: false)

        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.xrpToken, amount: adapter.baseReserve, address: Self.destination, destinationTag: nil)

        #expect(error == nil)
    }

    @Test func fundedDestinationTakesAnyAmount() async {
        let adapter = StubSendXrpAdapter(exists: true)

        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.xrpToken, amount: 1, address: Self.destination, destinationTag: nil)

        #expect(error == nil)
    }

    @Test func flaggedDestinationWithoutTagIsRefused() async {
        let adapter = StubSendXrpAdapter(exists: true, requiresTag: true)

        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.xrpToken, amount: 100, address: Self.destination, destinationTag: nil)

        #expect(error as? XrpSendHelper.TransactionError != nil)
        if case .destinationRequiresTag = error as? XrpSendHelper.TransactionError {} else {
            Issue.record("expected a required tag error, got \(String(describing: error))")
        }
    }

    @Test func flaggedDestinationWithATagPasses() async {
        let adapter = StubSendXrpAdapter(exists: true, requiresTag: true)

        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.xrpToken, amount: 100, address: Self.destination, destinationTag: 42)

        #expect(error == nil)
    }

    // an unknown flag is not the same as no flag: the payment would burn its fee on the ledger
    @Test func failedLookupBlocksTheSend() async {
        let adapter = StubSendXrpAdapter(exists: true, lookupError: StubError.unreachable)

        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.xrpToken, amount: 100, address: Self.destination, destinationTag: nil)

        #expect(error as? StubError == .unreachable)
    }

    // the account gate is for XRP itself; an issued token lands on a trust line, checked on the form
    @Test func issuedTokenSkipsTheAccountGate() async {
        let adapter = StubSendXrpAdapter(exists: false)

        let error = await XrpSendHelper.destinationError(adapter: adapter, token: Self.issuedToken, amount: 1, address: Self.destination, destinationTag: nil)

        #expect(error == nil)
    }
}

extension XrpDestinationGateTests {
    private static let destination = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"

    private static let xrpToken = Token(
        coin: Coin(uid: "ripple", name: "XRP", code: "XRP"),
        blockchain: Blockchain(type: .xrp, name: "XRP Ledger", explorerUrl: nil),
        type: .native,
        decimals: 6
    )

    private static let issuedToken = Token(
        coin: Coin(uid: "rlusd", name: "RLUSD", code: "RLUSD"),
        blockchain: Blockchain(type: .xrp, name: "XRP Ledger", explorerUrl: nil),
        type: .xrpAsset(currency: "RLUSD", issuer: destination),
        decimals: 15
    )

    enum StubError: Error, Equatable {
        case unreachable
    }

    private final class StubSendXrpAdapter: ISendXrpAdapter {
        private let exists: Bool
        private let requiresTag: Bool
        private let lookupError: Error?

        init(exists: Bool, requiresTag: Bool = false, lookupError: Error? = nil) {
            self.exists = exists
            self.requiresTag = requiresTag
            self.lookupError = lookupError
        }

        let address = "rU6K7V3Po4snVhBBaU29sesqs2qTQJWDw1"
        let fee: Decimal = 0.000012
        let baseReserve: Decimal = 1
        let ownerReserve: Decimal = 0.2
        let availableXrpBalance: Decimal = 100

        func doesAccountExist(address _: String) async throws -> Bool {
            if let lookupError { throw lookupError }
            return exists
        }

        func requiresDestinationTag(address _: String) async throws -> Bool {
            if let lookupError { throw lookupError }
            return requiresTag
        }

        func canReceive(address _: String) async throws -> Bool {
            if let lookupError { throw lookupError }
            return true
        }

        func send(amount _: Decimal, address _: String, destinationTag _: UInt32?, signer _: XrpKit.Signer) async throws -> String {
            fatalError("not sent in these tests")
        }

        func setTrustLine(currency _: String, issuer _: String, limit _: Decimal, signer _: XrpKit.Signer) async throws -> String {
            fatalError("not sent in these tests")
        }
    }
}
