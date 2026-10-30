import Foundation
import GRDB
import MarketKit
import Testing
@testable import WalletCore

/// The NEAR spam decision path, composed as SpamWrapper does for NEAR: OutgoingPoisoningFilter, then
/// Android's two passes (value first, correlation only in the gray zone). Addresses compare on 2
/// characters, a name without its top-level account. NEAR limit 0.01: spam < 0.001, risk (3) < 0.01,
/// danger (2) < 0.05.
struct NearSpamPolicyTests {
    /// a normal amount is trusted on its value alone, whoever paid the account before
    @Test func normalAmountFromAnotherNameIsNotSpam() throws {
        let spam = try isSpam(events: incoming(from: "bob.near", near: "50"), timestamp: 600, counterparties: [("alice.near", 0)])
        #expect(!spam)
    }

    /// ".near" is shared by every name, so it does not make two names alike
    @Test func dustFromAnUnrelatedNameIsNotSpam() throws {
        // 3 (risk) + 3 (within 20 minutes) = 6
        let spam = try isSpam(events: incoming(from: "bob.near", near: "0.005"), timestamp: 600, counterparties: [("alice.near", 0)])
        #expect(!spam)
    }

    @Test func dustFromALookalikeNameIsSpam() throws {
        // "alixe" vs "alice": "al" matches, 3 (risk) + 4 (prefix) = 7
        let spam = try isSpam(events: incoming(from: "alixe.near", near: "0.005"), timestamp: 999_999, counterparties: [("alice.near", 0)])
        #expect(spam)
    }

    @Test func lookalikeUnderAnotherTopLevelAccountIsSpam() throws {
        // "alice.tg" is another account than "alice.near": "alice" vs "alice" matches both ends, 3 (risk) + 8 = 11
        #expect(try isSpam(events: incoming(from: "alice.tg", near: "0.005"), timestamp: 999_999, counterparties: [("alice.near", 0)]))
        // "alise.tg" vs "alice.near": "al" matches
        #expect(try isSpam(events: incoming(from: "alise.tg", near: "0.005"), timestamp: 999_999, counterparties: [("alice.near", 0)]))
    }

    /// only the full address is a return: the account the user paid, whatever its case
    @Test func dustBackFromThePaidAccountIsNotALookalike() throws {
        #expect(try !isSpam(events: incoming(from: "Alice.NEAR", near: "0.005"), timestamp: 999_999, counterparties: [("alice.near", 0)]))
    }

    @Test func hexAccountsCompareOnTwoCharacters() throws {
        let cached = "abc" + String(repeating: "0", count: 58) + "fed"
        let lookalike = "abx" + String(repeating: "1", count: 58) + "xed"
        let unrelated = "xyc" + String(repeating: "1", count: 58) + "fzz"

        // 2 (danger) + 4 + 4
        #expect(try isSpam(events: incoming(from: lookalike, near: "0.02"), timestamp: 999_999, counterparties: [(cached, 0)]))
        #expect(try !isSpam(events: incoming(from: unrelated, near: "0.02"), timestamp: 999_999, counterparties: [(cached, 0)]))
    }

    @Test func dustBelowTheSpamLimitIsSpam() throws {
        #expect(try isSpam(events: incoming(from: "bob.near", near: "0.0005")))
    }

    @Test func zeroValueTokenIsScoredInTheGrayZone() throws {
        // 4 (zero value) + 3 (within 20 minutes) = 7
        let zero = TransferEvents(incoming: [TransferEvent(address: "bob.near", value: AppValue(token: Self.usdt, value: 0))])
        #expect(try isSpam(events: zero, timestamp: 600, counterparties: [("alice.near", 0)]))
        #expect(try !isSpam(events: zero, timestamp: 999_999, counterparties: [("alice.near", 0)]))
    }
}

extension NearSpamPolicyTests {
    private static let accountId = "near-spam-policy-tests"

    private static let near = Token(
        coin: Coin(uid: "near", name: "NEAR Protocol", code: "NEAR"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .native,
        decimals: 24
    )

    private static let usdt = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .nep141(contractId: "usdt.tether-token.near"),
        decimals: 6
    )

    private func incoming(from address: String, near value: String) -> TransferEvents {
        TransferEvents(incoming: [TransferEvent(address: address, value: AppValue(token: Self.near, value: Decimal(string: value)!))])
    }

    private func makeCache(counterparties: [(address: String, timestamp: Int)]) throws -> OutputTransactionCache {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("near-spam-policy-tests-\(UUID().uuidString).sqlite").path
        let storage = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))

        try storage.save(outgoingAddresses: counterparties.map {
            OutgoingAddress(address: $0.address, blockchainTypeUid: BlockchainType.near.uid, accountUid: Self.accountId, timestamp: $0.timestamp, blockHeight: nil)
        })

        let cache = OutputTransactionCache(storage: storage)
        cache.loadCache(for: .near, accountId: Self.accountId)
        return cache
    }

    private func isSpam(events: TransferEvents, timestamp: Int = 0, counterparties: [(address: String, timestamp: Int)] = []) throws -> Bool {
        let info = SpamTransactionInfo(hash: "hash", blockchainType: .near, timestamp: timestamp, blockHeight: nil, events: events)

        let filterChain = SpamFilterChain().append(OutgoingPoisoningFilter())
        if let result = filterChain.evaluate(info) {
            switch result {
            case .spam: return true
            case .trusted: return false
            case .ignore: break
            }
        }

        let cache = try makeCache(counterparties: counterparties)
        let evaluator = SpamScoreEvaluator().append(GrayZoneGateCondition(
            values: [ZeroValueCondition(), LowAmountCondition()],
            correlation: [
                AddressSimilarityCondition(cache: cache, minMatchLength: 2, normalize: SpamWrapper.addressNormalizer(blockchainType: .near)),
                TimeCorrelationCondition(cache: cache),
            ]
        ))

        switch evaluator.evaluate(SpamEvaluationContext(transaction: info)) {
        case .spam: return true
        case .suspicious, .trusted: return false
        }
    }
}
