import BigInt
import Foundation
import MarketKit
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainTransactionConverterTests {
    private static let own = "thor1x0jkvqdh2hlpeztd5zyyk70n3efx6mhudkmnn2"
    private static let other = "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008"

    @Test func plainSendProducesOneOutgoingRecord() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own, "THOR.RUNE", 100_000_000)],
                outgoing: [(Self.other, "THOR.RUNE", 100_000_000)]
            )
        )

        #expect(records.count == 1)
        let outgoing = try #require(records.first as? ThorChainOutgoingTransactionRecord)
        #expect(outgoing.to == Self.other)
        #expect(outgoing.value.value == -1)
        #expect(outgoing.sentToSelf == false)
    }

    @Test func plainReceiveProducesOneIncomingRecord() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.other, "THOR.RUNE", 250_000_000)],
                outgoing: [(Self.own, "THOR.RUNE", 250_000_000)]
            )
        )

        #expect(records.count == 1)
        let incoming = try #require(records.first as? ThorChainIncomingTransactionRecord)
        #expect(incoming.from == Self.other)
        #expect(incoming.value.value == Decimal(string: "2.5"))
    }

    // the defect the single-record converter had: a swap spends one asset and delivers
    // another in the same action, and only the spent side survived
    @Test func swapProducesBothSpentAndReceivedAssets() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own, "THOR.RUNE", 100_000_000)],
                outgoing: [(Self.own, "TCY", 500_000_000)]
            )
        )

        #expect(records.count == 2)

        let spent = try #require(records.compactMap { $0 as? ThorChainOutgoingTransactionRecord }.first)
        #expect(spent.value.value == -1)
        #expect(spent.value.token != nil, "RUNE must resolve to the base token")
        // no outgoing leg carries RUNE, so there is no counterparty for the spent side
        #expect(spent.to == nil)
        #expect(spent.sentToSelf == false)

        let received = try #require(records.compactMap { $0 as? ThorChainIncomingTransactionRecord }.first)
        #expect(received.value.value == 5)
        #expect(received.value.token == nil, "TCY has no MarketKit token and falls back to its ticker")
        #expect(received.value.code == "TCY")
    }

    @Test func knownThorChainAssetResolvesToItsMarketKitToken() throws {
        let tcy = Token(
            coin: Coin(uid: "tcy", name: "TCY", code: "TCY"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .thorChainAsset(denom: "tcy"),
            decimals: 8
        )
        let converter = try Self.converter(
            knownTokens: [TokenQuery(blockchainType: .thorChain, tokenType: .thorChainAsset(denom: "tcy")): tcy]
        )

        let records = converter.transactionRecords(
            from: Self.transaction(
                incoming: [(Self.other, "TCY", 500_000_000)],
                outgoing: [(Self.own, "TCY", 500_000_000)]
            )
        )

        let received = try #require(records.first as? ThorChainIncomingTransactionRecord)
        #expect(received.value.token?.coin.uid == "tcy")
        #expect(received.value.value == 5)
    }

    // Midgard reports the same asset in full notation for swaps, so the lookup must
    // normalise it to the bank denom before asking MarketKit
    @Test func fullNotationResolvesToTheSameTokenAsTheBankDenom() throws {
        let tcy = Token(
            coin: Coin(uid: "tcy", name: "TCY", code: "TCY"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .thorChainAsset(denom: "tcy"),
            decimals: 8
        )
        let converter = try Self.converter(
            knownTokens: [TokenQuery(blockchainType: .thorChain, tokenType: .thorChainAsset(denom: "tcy")): tcy]
        )

        let records = converter.transactionRecords(
            from: Self.transaction(
                incoming: [(Self.other, "THOR.TCY", 100_000_000)],
                outgoing: [(Self.own, "THOR.TCY", 100_000_000)]
            )
        )

        let received = try #require(records.first as? ThorChainIncomingTransactionRecord)
        #expect(received.value.token?.coin.uid == "tcy")
    }

    @Test func recordsOfOneActionGetDistinctUids() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own, "THOR.RUNE", 100_000_000)],
                outgoing: [(Self.own, "TCY", 500_000_000)]
            )
        )

        #expect(Set(records.map(\.uid)).count == records.count)
        #expect(records.allSatisfy { $0.transactionHash == Self.hash })
    }

    @Test func sameAssetOnBothSidesIsSentToSelfAndNotDuplicated() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own, "THOR.RUNE", 100_000_000)],
                outgoing: [(Self.own, "THOR.RUNE", 100_000_000)]
            )
        )

        #expect(records.count == 1)
        let outgoing = try #require(records.first as? ThorChainOutgoingTransactionRecord)
        #expect(outgoing.sentToSelf)
    }

    // in a swap the first outgoing entry is the user's own receive of the other asset —
    // taking it as the recipient would name the user as their own counterparty
    @Test func counterpartyIsMatchedByAssetNotByPosition() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own, "THOR.RUNE", 100_000_000)],
                outgoing: [
                    (Self.own, "TCY", 500_000_000),
                    (Self.other, "THOR.RUNE", 100_000_000),
                ]
            )
        )

        let spent = try #require(records.compactMap { $0 as? ThorChainOutgoingTransactionRecord }.first)
        #expect(spent.to == Self.other)
    }

    @Test func actionWithoutTheUserProducesNoRecords() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.other, "THOR.RUNE", 100_000_000)],
                outgoing: [(Self.other, "THOR.RUNE", 100_000_000)]
            )
        )

        #expect(records.isEmpty)
    }

    @Test func ownAddressIsMatchedCaseInsensitively() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own.uppercased(), "THOR.RUNE", 100_000_000)],
                outgoing: [(Self.other, "THOR.RUNE", 100_000_000)]
            )
        )

        #expect(records.count == 1)
    }

    // Midgard reports swaps in full notation but native sends in bank-denom notation;
    // both must resolve to RUNE and carry the base token
    @Test func bankDenomRuneResolvesToTheBaseToken() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [(Self.own, "rune", 100_000_000)],
                outgoing: [(Self.other, "rune", 100_000_000)]
            )
        )

        let outgoing = try #require(records.first as? ThorChainOutgoingTransactionRecord)
        #expect(outgoing.value.token != nil)
        #expect(outgoing.value.value == -1)
    }

    @Test func multipleLegsOfTheSameAssetEachProduceARecord() throws {
        let records = try Self.converter().transactionRecords(
            from: Self.transaction(
                incoming: [
                    (Self.own, "THOR.RUNE", 100_000_000),
                    (Self.own, "THOR.RUNE", 300_000_000),
                ],
                outgoing: [(Self.other, "THOR.RUNE", 400_000_000)]
            )
        )

        #expect(records.count == 2)
        #expect(records.compactMap { ($0 as? ThorChainOutgoingTransactionRecord)?.value.value } == [-1, -3])
    }

    // MARK: - support

    private static let hash = String(repeating: "A", count: 64)

    private static func converter(knownTokens: [TokenQuery: Token] = [:]) throws -> ThorChainTransactionConverter {
        let address = try ThorChainKit.Address(own, network: .mainnet)
        let endpoints = try ThorChainKit.EndpointConfiguration(families: [
            ThorChainKit.EndpointFamilyDescriptor(
                id: "converter-test",
                cosmosRestURL: URL(string: "https://converter-rest.example")!,
                cometBftURL: URL(string: "https://converter-rpc.example")!
            ),
        ])
        let kit = try ThorChainKit.Kit.instance(address: address, walletId: "converter-\(UUID().uuidString)", endpoints: endpoints)

        return ThorChainTransactionConverter(
            source: TransactionSource(blockchainType: .thorChain, meta: nil),
            baseToken: token(),
            coinManager: StubCoinManager(tokens: knownTokens),
            thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: kit, signer: nil)
        )
    }

    private static func token() -> Token {
        Token(
            coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }

    private static func transaction(
        incoming: [(String, String, BigUInt)],
        outgoing: [(String, String, BigUInt)]
    ) -> ThorChainKit.Transaction {
        ThorChainKit.Transaction(
            transactionId: ThorChainKit.TransactionID(hash: hash)!,
            blockHeight: 27_000_000,
            timestamp: Date(timeIntervalSince1970: 1_785_427_946),
            type: "send",
            status: "success",
            memo: nil,
            incoming: incoming.map { ThorChainKit.CoinTransfer(address: $0.0, asset: $0.1, amount: $0.2) },
            outgoing: outgoing.map { ThorChainKit.CoinTransfer(address: $0.0, asset: $0.1, amount: $0.2) }
        )
    }
}

private struct StubCoinManager: ICoinManager {
    let tokens: [TokenQuery: Token]

    func token(query: TokenQuery) throws -> Token? {
        tokens[query]
    }
}
