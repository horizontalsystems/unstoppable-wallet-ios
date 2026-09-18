import Foundation
import GRDB
import MarketKit
import Testing
@testable import WalletCore

// XRP dust through the shared (non-Solana) chain SpamManager composes: ZeroValue +
// AddressSimilarity + LowAmount + TimeCorrelation. XRP limit 0.001 → spam < 0.0001,
// risk < 0.001, danger < 0.005.
struct XrpSpamPolicyTests {
    // The reported case: 0.00001 XRP from an unknown account
    @Test func dustBelowSpamLimitIsSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "0.00001")])
        #expect(try isSpam(events: events) == true)
    }

    @Test func amountAtSpamLimitIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "0.0001")])
        #expect(try isSpam(events: events) == false)
    }

    @Test func amountUnderDangerLimitIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "0.002")])
        #expect(try isSpam(events: events) == false)
    }

    @Test func ordinaryAmountIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "12")])
        #expect(try isSpam(events: events) == false)
    }

    // The base reserve arriving to activate an account must never be hidden
    @Test func firstDepositIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "1")])
        #expect(try isSpam(events: events) == false)
    }

    // An outgoing dust leg is the user's own send: the negative value must not score
    @Test func outgoingDustLegIsInert() throws {
        let events = TransferEvents(incoming: [event(xrp: "12")], outgoing: [event(xrp: "-0.00001")])
        #expect(try isSpam(events: events) == false)
    }

    // A gray-zone amount alone stays visible; a look-alike of a known counterparty pushes it over
    @Test func grayZoneAmountAloneIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "0.0005", from: Self.mimic)])
        #expect(try isSpam(events: events, timestamp: 1000) == false)
    }

    @Test func grayZoneAmountFromLookAlikeSenderIsSpam() throws {
        let events = TransferEvents(incoming: [event(xrp: "0.0005", from: Self.mimic)])
        #expect(try isSpam(events: events, timestamp: 1000, counterparties: [(Self.realSender, 900)]) == true)
    }

    @Test func emptyEventsAreNotSpam() throws {
        #expect(try isSpam(events: TransferEvents()) == false)
    }
}

extension XrpSpamPolicyTests {
    private static let address = "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"
    private static let realSender = "rMxCKbEDwqr76QuheSUMdEGf4B9xJ8m5De"
    // shares the first and last four characters with realSender, the shape poisoning uses
    private static let mimic = "rMxC7tPhZzKbvWnQsRgYuLdEfHaJmN8m5De"
    private static let accountId = "xrp-spam-policy-tests"

    private static let xrpToken = Token(
        coin: Coin(uid: "ripple", name: "XRP", code: "XRP"),
        blockchain: Blockchain(type: .xrp, name: "XRP Ledger", explorerUrl: nil),
        type: .native,
        decimals: 6
    )

    private func event(xrp amount: String, from: String = XrpSpamPolicyTests.address) -> TransferEvent {
        TransferEvent(address: from, value: AppValue(token: Self.xrpToken, value: Decimal(string: amount)!))
    }

    private func makeCache(counterparties: [(address: String, timestamp: Int)]) throws -> OutputTransactionCache {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("xrp-spam-policy-tests-\(UUID().uuidString).sqlite").path
        let storage = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))

        try storage.save(outgoingAddresses: counterparties.map {
            OutgoingAddress(address: $0.address, blockchainTypeUid: BlockchainType.xrp.uid, accountUid: Self.accountId, timestamp: $0.timestamp, blockHeight: nil)
        })

        let cache = OutputTransactionCache(storage: storage)
        cache.loadCache(for: .xrp, accountId: Self.accountId)
        return cache
    }

    // The composition SpamWrapper builds for every chain except Solana
    private func isSpam(events: TransferEvents, timestamp: Int = 0, counterparties: [(address: String, timestamp: Int)] = []) throws -> Bool {
        let info = SpamTransactionInfo(hash: "hash", blockchainType: .xrp, timestamp: timestamp, blockHeight: nil, events: events)

        let filterChain = SpamFilterChain().append(OutgoingPoisoningFilter())
        if let result = filterChain.evaluate(info) {
            switch result {
            case .spam: return true
            case .trusted: return false
            case .ignore: break
            }
        }

        let cache = try makeCache(counterparties: counterparties)
        let evaluator = SpamScoreEvaluator()
            .append(ZeroValueCondition())
            .append(AddressSimilarityCondition(cache: cache))
            .append(LowAmountCondition())
            .append(TimeCorrelationCondition(cache: cache))

        switch evaluator.evaluate(SpamEvaluationContext(transaction: info)) {
        case .spam: return true
        case .suspicious, .trusted: return false
        }
    }
}
