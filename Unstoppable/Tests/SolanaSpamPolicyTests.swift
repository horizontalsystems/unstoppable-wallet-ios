import EvmKit
import Foundation
import GRDB
import MarketKit
import Testing
import TronKit
@testable import WalletCore

// Android-parity fixtures for the Solana spam decision path:
// SpamFilterChain (OutgoingPoisoningFilter) + SolanaLowAmountCondition + AddressSimilarity/TimeCorrelation,
// composed the same way SpamManager.evaluateSpam does. SOL limit 0.0001: spam < 0.00001, risk < 0.0001, danger < 0.0005.
struct SolanaSpamPolicyTests {
    // MARK: - Direct incoming

    @Test func rawIncomingIsSpam() throws {
        let events = TransferEvents(incoming: [event(raw: 1)])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func zeroNativeIncomingIsSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0")])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func zeroKnownSplWithoutLimitIsSpam() throws {
        let events = TransferEvents(incoming: [event(ray: "0")])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func nativeDustBelowSpamThresholdIsSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0.000001")])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func nativeExactlyAtSpamThresholdIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0.00001")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    @Test func nativeBetweenSpamAndRiskLimitIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0.00005")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    @Test func nativeAboveDangerLimitIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0.5")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    @Test func suspiciousOnlyTokenAmountIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(usdc: "0.5")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    @Test func emptyEventsAreNotSpam() throws {
        let spam = try isSpam(events: TransferEvents())
        #expect(spam == false)
    }

    // MARK: - Mixed Unknown

    @Test func outgoingNativeDustLegIsInert() throws {
        let events = TransferEvents(incoming: [event(usdc: "5")], outgoing: [event(sol: "-0.000001")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    @Test func outgoingKnownSplDustLegIsSpam() throws {
        let events = TransferEvents(incoming: [event(usdc: "5")], outgoing: [event(usdc: "-0.05")])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func outgoingKnownSplNormalLegIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(usdc: "5")], outgoing: [event(usdc: "-5")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    @Test func outgoingRawLegIsSpam() throws {
        let events = TransferEvents(incoming: [event(usdc: "5")], outgoing: [event(raw: 1)])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func outgoingZeroNativeLegIsSpam() throws {
        let events = TransferEvents(incoming: [event(usdc: "5")], outgoing: [event(sol: "0")])
        let spam = try isSpam(events: events)
        #expect(spam == true)
    }

    @Test func nativeLegsScorePerEventNotAsSignedSum() throws {
        let events = TransferEvents(incoming: [event(sol: "0.5")], outgoing: [event(sol: "-0.5")])
        let spam = try isSpam(events: events)
        #expect(spam == false)
    }

    // MARK: - Counterparty correlation (Android regression: watch address 3VHMK…LH7Q)

    // 100 SOL arrived from realSender, seconds later 0.00001 SOL dust from a look-alike of that sender.
    // Dust alone is +3 (at the spam threshold, strict <); prefix +4, suffix +4 and time +3 push it over.
    @Test func dustMimicOfIncomingSenderIsSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0.00001", from: Self.dustMimic)])
        let spam = try isSpam(events: events, timestamp: 1000, counterparties: [(Self.realSender, 900)])
        #expect(spam == true)
    }

    @Test func dustMimicWithoutContextIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "0.00001", from: Self.dustMimic)])
        let spam = try isSpam(events: events, timestamp: 1000)
        #expect(spam == false)
    }

    // A Solana counterparty carries no block height, so proximity is worth the time score (+3) only:
    // dust +3 and time +3 stay below the threshold. A block bonus (+4) would wrongly make this spam.
    @Test func timeCorrelationAloneStaysBelowThreshold() throws {
        let events = TransferEvents(incoming: [event(sol: "0.00005", from: Self.dustMimic)])
        let spam = try isSpam(events: events, timestamp: 1000, counterparties: [(Self.address, 900)])
        #expect(spam == false)
    }

    // Correlation is gated to the gray zone: a normal amount scores 0 and exits before any look-alike check
    @Test func normalAmountFromMimicIsNotSpam() throws {
        let events = TransferEvents(incoming: [event(sol: "1", from: Self.dustMimic)])
        let spam = try isSpam(events: events, timestamp: 1000, counterparties: [(Self.realSender, 900)])
        #expect(spam == false)
    }
}

// MARK: - Counterparty factory

struct SpamCounterpartyFactoryTests {
    private let factory = OutputTransactionFactory()

    @Test func evmIncomingSenderIsCounterparty() {
        let token = Self.token(blockchainType: .ethereum, code: "ETH")
        let record = EvmIncomingTransactionRecord(
            source: TransactionSource(blockchainType: .ethereum, meta: nil),
            transaction: EvmKit.Transaction(hash: Data([0x01]), timestamp: 1000, isFailed: false, blockNumber: 777),
            baseToken: token,
            from: "0xsender",
            value: AppValue(token: token, value: 1)
        )

        let cached = factory.cachedOutputs(from: record)

        #expect(cached.map(\.address) == ["0xsender"])
        #expect(cached.first?.timestamp == 1000)
        #expect(cached.first?.blockHeight == 777)
    }

    @Test func evmOutgoingRecipientStillWins() {
        let token = Self.token(blockchainType: .ethereum, code: "ETH")
        let record = EvmOutgoingTransactionRecord(
            source: TransactionSource(blockchainType: .ethereum, meta: nil),
            transaction: EvmKit.Transaction(hash: Data([0x02]), timestamp: 1000, isFailed: false),
            baseToken: token,
            to: "0xrecipient",
            value: AppValue(token: token, value: 1),
            sentToSelf: false,
            protected: false
        )

        #expect(factory.cachedOutputs(from: record).map(\.address) == ["0xrecipient"])
    }

    @Test func tronIncomingSenderIsCounterparty() {
        let token = Self.token(blockchainType: .tron, code: "TRX")
        let record = TronIncomingTransactionRecord(
            source: TransactionSource(blockchainType: .tron, meta: nil),
            transaction: TronKit.Transaction(hash: Data([0x03]), timestamp: 1000, isFailed: false, blockNumber: 55, confirmed: true),
            baseToken: token,
            from: "Tsender",
            value: AppValue(token: token, value: 1)
        )

        #expect(factory.cachedOutputs(from: record).map(\.address) == ["Tsender"])
    }

    // Records that only carry a placeholder height (Solana stores 0 once confirmed) must not feed block correlation
    @Test func placeholderBlockHeightIsDropped() {
        let token = Self.token(blockchainType: .ethereum, code: "ETH")
        let record = EvmIncomingTransactionRecord(
            source: TransactionSource(blockchainType: .ethereum, meta: nil),
            transaction: EvmKit.Transaction(hash: Data([0x04]), timestamp: 1000, isFailed: false, blockNumber: 0),
            baseToken: token,
            from: "0xsender",
            value: AppValue(token: token, value: 1)
        )

        #expect(factory.cachedOutputs(from: record).first?.blockHeight == nil)
    }

    private static func token(blockchainType: BlockchainType, code: String) -> Token {
        Token(
            coin: Coin(uid: code.lowercased(), name: code, code: code),
            blockchain: Blockchain(type: blockchainType, name: code, explorerUrl: nil),
            type: .native,
            decimals: 18
        )
    }
}

extension SolanaSpamPolicyTests {
    private static let address = "5n7Qw3XkXm1WybwHHM2SGwiZTLc2yLYhcaAtGYRDR1Vp"
    private static let realSender = "6pRr7fQbrfpYUXZERLmxoKCaqXrz3ix6LQJGHVxSibvF"
    private static let dustMimic = "6pRrcG2PQrFfUL4dmGQFfFoD6bUnBNFGQ6AyQS2wibvF"
    private static let accountId = "spam-policy-tests"

    private static let solToken = Token(
        coin: Coin(uid: "solana", name: "Solana", code: "SOL"),
        blockchain: Blockchain(type: .solana, name: "Solana", explorerUrl: nil),
        type: .native,
        decimals: 9
    )

    private static let usdcToken = Token(
        coin: Coin(uid: "usd-coin", name: "USD Coin", code: "USDC"),
        blockchain: Blockchain(type: .solana, name: "Solana", explorerUrl: nil),
        type: .spl(address: "usdc-mint"),
        decimals: 6
    )

    private static let rayToken = Token(
        coin: Coin(uid: "raydium", name: "Raydium", code: "RAY"),
        blockchain: Blockchain(type: .solana, name: "Solana", explorerUrl: nil),
        type: .spl(address: "ray-mint"),
        decimals: 6
    )

    private func event(sol amount: String, from: String = SolanaSpamPolicyTests.address) -> TransferEvent {
        TransferEvent(address: from, value: AppValue(token: Self.solToken, value: Decimal(string: amount)!))
    }

    private func event(usdc amount: String) -> TransferEvent {
        TransferEvent(address: Self.address, value: AppValue(token: Self.usdcToken, value: Decimal(string: amount)!))
    }

    private func event(ray amount: String) -> TransferEvent {
        TransferEvent(address: Self.address, value: AppValue(token: Self.rayToken, value: Decimal(string: amount)!))
    }

    private func event(raw amount: Decimal) -> TransferEvent {
        TransferEvent(address: Self.address, value: AppValue(value: amount))
    }

    // Seeds the persisted counterparty context the way SpamManager builds it from earlier records
    private func makeCache(counterparties: [(address: String, timestamp: Int)]) throws -> OutputTransactionCache {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("spam-policy-tests-\(UUID().uuidString).sqlite").path
        let storage = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))

        try storage.save(outgoingAddresses: counterparties.map {
            OutgoingAddress(address: $0.address, blockchainTypeUid: BlockchainType.solana.uid, accountUid: Self.accountId, timestamp: $0.timestamp, blockHeight: nil)
        })

        let cache = OutputTransactionCache(storage: storage)
        cache.loadCache(for: .solana, accountId: Self.accountId)
        return cache
    }

    private func isSpam(events: TransferEvents, timestamp: Int = 0, counterparties: [(address: String, timestamp: Int)] = []) throws -> Bool {
        // blockHeight 0 mirrors a confirmed Solana record
        let info = SpamTransactionInfo(hash: "hash", blockchainType: .solana, timestamp: timestamp, blockHeight: 0, events: events)

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
            value: SolanaLowAmountCondition(),
            correlation: [AddressSimilarityCondition(cache: cache), TimeCorrelationCondition(cache: cache)]
        ))

        switch evaluator.evaluate(SpamEvaluationContext(transaction: info)) {
        case .spam: return true
        case .suspicious, .trusted: return false
        }
    }
}
