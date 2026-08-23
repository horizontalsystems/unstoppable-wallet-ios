import EvmKit
import Foundation
import GRDB
import MarketKit
import Testing
@testable import WalletCore

// Android-parity fixtures for the shared correlation machinery:
// prefix/suffix length, inclusive thresholds, any-entry proximity, a window of distinct counterparties.
struct SpamCorrelationTests {
    // MARK: - Address similarity

    // EVM/Tron/Stellar are ungated, so they keep the 4-character match; Solana (gated) uses Android's 3
    @Test func matchLengthIsFourByDefaultAndThreeForSolana() throws {
        let cache = try makeCache(rows: [("0xabc000000000000000000000000000000000fed", 0, nil)])
        let context = context(from: "0xabc111111111111111111111111111111111fed", timestamp: 0)

        #expect(AddressSimilarityCondition(cache: cache).evaluate(context) == 0)
        #expect(AddressSimilarityCondition(cache: cache, minMatchLength: 3).evaluate(context) == 8)
    }

    @Test func tronLeadingTIsStripped() throws {
        let cached = "TABC" + String(repeating: "x", count: 29) + "1"
        let incoming = "TABC" + String(repeating: "y", count: 29) + "2"
        let cache = try makeCache(blockchainType: .tron, rows: [(cached, 0, nil)])
        let context = context(blockchainType: .tron, from: incoming, timestamp: 0)

        // without stripping, "TABC" == "TABC" would score the prefix
        #expect(AddressSimilarityCondition(cache: cache).evaluate(context) == 0)
    }

    // MARK: - Time / block correlation

    @Test func timeThresholdIsInclusive() throws {
        let cache = try makeCache(rows: [(Self.counterparty, 0, nil)])

        #expect(TimeCorrelationCondition(cache: cache).evaluate(context(timestamp: 1200)) == 3)
        #expect(TimeCorrelationCondition(cache: cache).evaluate(context(timestamp: 1201)) == 0)
    }

    @Test func blockThresholdIsInclusiveAndPreferred() throws {
        let cache = try makeCache(rows: [(Self.counterparty, 0, 100)])

        #expect(TimeCorrelationCondition(cache: cache).evaluate(context(timestamp: 999_999, blockHeight: 105)) == 4)
        #expect(TimeCorrelationCondition(cache: cache).evaluate(context(timestamp: 999_999, blockHeight: 106)) == 0)
    }

    // The most recent entry is far away; an older one in the window is close enough
    @Test func anyEntryInWindowCorrelates() throws {
        let cache = try makeCache(rows: [("0xfar", 5000, nil), ("0xnear", 900, nil)])

        #expect(TimeCorrelationCondition(cache: cache).evaluate(context(timestamp: 1000)) == 3)
    }

    // MARK: - Window

    @Test func windowKeepsTenMostRecentDistinctAddresses() throws {
        let rows = (0 ..< 15).map { ("0xcounterparty$0", $0 * 10, Int?.none) }
        let cache = try makeCache(rows: rows)

        let window = cache.get(blockchainType: .ethereum)
        #expect(window.count == 10)
        #expect(window.first?.timestamp == 140)
    }

    // A repeated counterparty moves to the front instead of taking a second slot
    @Test func addDedupsRepeatedAddress() throws {
        let cache = try makeCache(rows: [])
        let token = Self.ethToken

        for hash: UInt8 in [1, 2] {
            let record = EvmIncomingTransactionRecord(
                source: TransactionSource(blockchainType: .ethereum, meta: nil),
                transaction: EvmKit.Transaction(hash: Data([hash]), timestamp: Int(hash), isFailed: false),
                baseToken: token,
                from: Self.counterparty,
                value: AppValue(token: token, value: 1)
            )
            cache.add(record: record, accountId: Self.accountId)
        }

        let window = cache.get(blockchainType: .ethereum)
        #expect(window.count == 1)
        #expect(window.first?.timestamp == 2)
    }

    // MARK: - Own send vs scored record

    @Test func externalContractCallIsScoredNotTrusted() {
        let token = Self.ethToken
        let record = ExternalContractCallTransactionRecord(
            source: TransactionSource(blockchainType: .ethereum, meta: nil),
            transaction: EvmKit.Transaction(hash: Data([0x05]), timestamp: 1, isFailed: false),
            baseToken: token,
            incomingEvents: [TransferEvent(address: "0xsender", value: AppValue(token: token, value: 1))],
            outgoingEvents: [TransferEvent(address: "0xrecipient", value: AppValue(token: token, value: 1))],
            protected: false
        )

        #expect(OutputTransactionFactory.outgoingAddresses(from: record) == nil)
        #expect(OutputTransactionFactory.counterpartyAddresses(from: record) == ["0xrecipient"])
    }

    @Test func ownContractCallWithoutSentLegIsTrustedAndCachesSender() {
        let token = Self.ethToken
        let record = ContractCallTransactionRecord(
            source: TransactionSource(blockchainType: .ethereum, meta: nil),
            transaction: EvmKit.Transaction(hash: Data([0x06]), timestamp: 1, isFailed: false),
            baseToken: token,
            contractAddress: "0xcontract",
            method: nil,
            incomingEvents: [TransferEvent(address: "0xpool", value: AppValue(token: token, value: 1))],
            outgoingEvents: [],
            protected: false
        )

        #expect(OutputTransactionFactory.outgoingAddresses(from: record) == [])
        #expect(OutputTransactionFactory().cachedOutputs(from: record).map(\.address) == ["0xpool"])
    }
}

extension SpamCorrelationTests {
    private static let counterparty = "0x1111111111111111111111111111111111111111"
    private static let accountId = "spam-correlation-tests"

    private static let ethToken = Token(
        coin: Coin(uid: "ethereum", name: "Ethereum", code: "ETH"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
        type: .native,
        decimals: 18
    )

    private func makeCache(blockchainType: BlockchainType = .ethereum, rows: [(address: String, timestamp: Int, blockHeight: Int?)]) throws -> OutputTransactionCache {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("spam-correlation-tests-\(UUID().uuidString).sqlite").path
        let storage = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))

        try storage.save(outgoingAddresses: rows.map {
            OutgoingAddress(address: $0.address, blockchainTypeUid: blockchainType.uid, accountUid: Self.accountId, timestamp: $0.timestamp, blockHeight: $0.blockHeight)
        })

        let cache = OutputTransactionCache(storage: storage)
        cache.loadCache(for: blockchainType, accountId: Self.accountId)
        return cache
    }

    private func context(blockchainType: BlockchainType = .ethereum, from: String = "0x9999999999999999999999999999999999999999", timestamp: Int, blockHeight: Int? = nil) -> SpamEvaluationContext {
        let info = SpamTransactionInfo(
            hash: "hash",
            blockchainType: blockchainType,
            timestamp: timestamp,
            blockHeight: blockHeight,
            events: TransferEvents(incoming: [TransferEvent(address: from, value: AppValue(token: Self.ethToken, value: 1))])
        )
        return SpamEvaluationContext(transaction: info)
    }
}

// MARK: - Shared value scoring over both legs (External records are now scored)

struct SpamSharedValueScoringTests {
    private static let usdt = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
        type: .eip20(address: "0xusdt"),
        decimals: 6
    )

    // Outgoing legs are stored negative; Android scores dust only for positive values
    @Test func negativeOutgoingLegNeverScoresAsDust() {
        let events = TransferEvents(
            incoming: [TransferEvent(address: "0xsender", value: AppValue(token: Self.usdt, value: 5))],
            outgoing: [TransferEvent(address: "0xrecipient", value: AppValue(token: Self.usdt, value: -0.05))]
        )

        #expect(LowAmountCondition().evaluate(context(events: events)) == 0)
    }

    @Test func positiveIncomingDustStillScores() {
        let events = TransferEvents(incoming: [TransferEvent(address: "0xsender", value: AppValue(token: Self.usdt, value: 0.05))])

        #expect(LowAmountCondition().evaluate(context(events: events)) == 7)
    }

    private func context(events: TransferEvents) -> SpamEvaluationContext {
        SpamEvaluationContext(transaction: SpamTransactionInfo(hash: "hash", blockchainType: .ethereum, timestamp: 0, blockHeight: nil, events: events))
    }
}
