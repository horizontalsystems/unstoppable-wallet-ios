import Foundation
import GRDB
import MarketKit
import Testing
@testable import WalletCore

struct SwapStorageOperationTests {
    @Test func operationSurvivesSaveAndRead() throws {
        let (storage, _) = try Self.storage()
        try storage.save(swap: Self.swap(uid: "swap", operation: .swap))
        try storage.save(swap: Self.swap(uid: "private", operation: .privateSend))
        try storage.save(swap: Self.swap(uid: "cross", operation: .crossPay))

        let swaps = try storage.swaps(accountId: Self.accountId, limit: 10)
        let operations = Dictionary(uniqueKeysWithValues: swaps.map { ($0.uid, $0.operation) })

        #expect(operations == ["swap": .swap, "private": .privateSend, "cross": .crossPay])
    }

    @Test func unknownOperationReadsAsSwap() throws {
        let (storage, dbPool) = try Self.storage()
        try storage.save(swap: Self.swap(uid: "future", operation: .crossPay))
        try dbPool.write { db in
            try db.execute(sql: "UPDATE \(SwapRecord.databaseTableName) SET \(SwapRecord.Columns.operation.name) = 'future_type'")
        }

        let swaps = try storage.swaps(accountId: Self.accountId, limit: 1)
        let swap = try #require(swaps.first)

        #expect(swap.operation == .swap)
    }

    @Test func statusUpdatesKeepOperation() throws {
        let (storage, _) = try Self.storage()
        try storage.save(swap: Self.swap(uid: "cross", operation: .crossPay, trackingHandle: "cross-handle"))
        try storage.save(swap: Self.swap(uid: "private", operation: .privateSend, trackingHandle: "private-handle"))

        let failed = try storage.markFailed(trackingHandle: "cross-handle")
        let retried = try storage.markNotStarted(trackingHandle: "cross-handle")
        let resolved = try storage.setTxHash("0xhash", trackingHandle: "cross-handle")
        let released = try storage.clearTrackingHandle("private-handle")
        #expect(failed && retried && resolved && released)

        let swaps = try storage.swaps(accountId: Self.accountId, limit: 10)
        let cross = try #require(swaps.first { $0.uid == "cross" })
        let privateSend = try #require(swaps.first { $0.uid == "private" })

        #expect(cross.txHash == "0xhash")
        #expect(cross.operation == .crossPay)
        #expect(privateSend.trackingHandle == nil)
        #expect(privateSend.operation == .privateSend)
    }

    @Test func splitOutputsSurviveSaveAndRead() throws {
        let (storage, _) = try Self.storage()
        let leg = Swap.Leg(status: .pending, type: "native_send", chainId: "bitcoin", txHash: "", fromAsset: "BTC.BTC", toAsset: "BTC.BTC")
        let refundLeg = Swap.Leg(
            status: .completed, type: "native_send", chainId: "bitcoin", txHash: "0xrefund", fromAsset: "BTC.BTC", toAsset: "BTC.BTC",
            toAddress: "bc1qrefund", toAmount: 0.35, outputIndex: 1, refund: true
        )
        let outputs = [
            Swap.Output(index: 0, status: .completed, toAddress: "bc1qfirst", fromAmount: 0.6, toAmount: 1.25, legs: []),
            Swap.Output(index: 1, status: .swapping, toAddress: "bc1qsecond", fromAmount: 0.4, toAmount: nil, legs: [leg, refundLeg]),
        ]
        var swap = Self.swap(uid: "split", operation: .splitSwap)
        swap.outputs = outputs
        swap.legs = [refundLeg]
        try storage.save(swap: swap)

        let saved = try #require(try storage.swaps(accountId: Self.accountId, limit: 1).first)

        #expect(saved.outputs == outputs)
        #expect(saved.legs == [refundLeg])
    }

    /// Rows written before split payout legs existed carry none of the new leg keys
    @Test func legWithoutSplitKeysDecodes() throws {
        let (storage, dbPool) = try Self.storage()
        try storage.save(swap: Self.swap(uid: "old", operation: .splitSwap))
        let legs = #"[{"status":"completed","type":"native_send","chainId":"bitcoin","txHash":"0xdeposit","fromAsset":"BTC.BTC","toAsset":"BTC.BTC"}]"#
        try dbPool.write { db in
            try db.execute(sql: "UPDATE \(SwapRecord.databaseTableName) SET \(SwapRecord.Columns.legs.name) = ?", arguments: [legs])
        }

        let saved = try #require(try storage.swaps(accountId: Self.accountId, limit: 1).first)
        let leg = try #require(saved.legs?.first)

        #expect(leg.txHash == "0xdeposit")
        #expect(leg.refund == false)
        #expect(leg.outputIndex == nil)
        #expect(leg.toAddress == nil)
        #expect(leg.toAmount == nil)
    }

    @Test func swapsFilterByOperation() throws {
        let (storage, _) = try Self.storage()
        try Self.saveOneOfEachOperation(storage: storage)

        let privateSends = try storage.swaps(accountId: Self.accountId, operation: .privateSend, limit: 10)
        let swaps = try storage.swaps(accountId: Self.accountId, operation: .swap, limit: 10)

        #expect(privateSends.map(\.uid) == ["private"])
        #expect(swaps.map(\.uid) == ["swap"])
    }

    @Test func nilOperationReturnsAll() throws {
        let (storage, _) = try Self.storage()
        try Self.saveOneOfEachOperation(storage: storage)

        let swaps = try storage.swaps(accountId: Self.accountId, operation: nil, limit: 10)

        #expect(Set(swaps.map(\.uid)) == ["swap", "private", "cross", "split"])
    }

    @Test func operationFilterPaginates() throws {
        let (storage, _) = try Self.storage()
        let now = Date()

        // Newest first: private-1, swap-1, private-2, swap-2, private-3, swap-3
        for index in 0 ..< 3 {
            let privateDate = now.addingTimeInterval(-Double(index * 2) * 60)
            let swapDate = now.addingTimeInterval(-Double(index * 2 + 1) * 60)
            try storage.save(swap: Self.swap(uid: "private-\(index + 1)", operation: .privateSend, date: privateDate))
            try storage.save(swap: Self.swap(uid: "swap-\(index + 1)", operation: .swap, date: swapDate))
        }

        let firstPage = try storage.swaps(accountId: Self.accountId, operation: .privateSend, limit: 2)
        #expect(firstPage.map(\.uid) == ["private-1", "private-2"])

        let cursor = try #require(firstPage.last?.date)
        let secondPage = try storage.swaps(accountId: Self.accountId, from: cursor, operation: .privateSend, limit: 2)
        #expect(secondPage.map(\.uid) == ["private-3"])
    }

    @Test func operationsFilterReturnsSwapAndSplitSwapOnly() throws {
        let (storage, _) = try Self.storage()
        let now = Date()
        try storage.save(swap: Self.swap(uid: "swap", operation: .swap, date: now.addingTimeInterval(-60)))
        try storage.save(swap: Self.swap(uid: "private", operation: .privateSend, date: now.addingTimeInterval(-120)))
        try storage.save(swap: Self.swap(uid: "split", operation: .splitSwap, date: now.addingTimeInterval(-180)))
        try storage.save(swap: Self.swap(uid: "cross", operation: .crossPay, date: now.addingTimeInterval(-240)))

        let swaps = try storage.swaps(accountId: Self.accountId, operations: [.swap, .splitSwap], limit: 10)

        #expect(swaps.map(\.uid) == ["swap", "split"])
    }

    @Test func blockchainTypeFilterMatchesEitherSide() throws {
        let (storage, _) = try Self.storage()
        try storage.save(swap: Self.swap(uid: "eth-btc", operation: .swap, tokenIn: Self.ethereumToken, tokenOut: Self.token))
        try storage.save(swap: Self.swap(uid: "tron-tron", operation: .swap, tokenIn: Self.tronToken, tokenOut: Self.tronToken))

        let ethereum = try storage.swaps(accountId: Self.accountId, blockchainType: .ethereum, limit: 10)
        let bitcoin = try storage.swaps(accountId: Self.accountId, blockchainType: .bitcoin, limit: 10)
        let tron = try storage.swaps(accountId: Self.accountId, blockchainType: .tron, limit: 10)

        #expect(ethereum.map(\.uid) == ["eth-btc"])
        #expect(bitcoin.map(\.uid) == ["eth-btc"])
        #expect(tron.map(\.uid) == ["tron-tron"])
    }

    @Test func tokenFilterTakesPrecedenceOverBlockchainType() throws {
        let (storage, _) = try Self.storage()
        try storage.save(swap: Self.swap(uid: "btc", operation: .swap))
        try storage.save(swap: Self.swap(uid: "tron", operation: .swap, tokenIn: Self.tronToken, tokenOut: Self.tronToken))

        let swaps = try storage.swaps(accountId: Self.accountId, token: Self.token, blockchainType: .tron, limit: 10)

        #expect(swaps.map(\.uid) == ["btc"])
    }

    @Test func addressesFilterMatchesRecipientToAddressOrSourceCaseInsensitively() throws {
        let (storage, _) = try Self.storage()
        let now = Date()
        try storage.save(swap: Self.swap(uid: "recipient", operation: .swap, recipient: "0xAbCdEf01", toAddress: "0xdeposit", date: now.addingTimeInterval(-60)))
        try storage.save(swap: Self.swap(uid: "to", operation: .swap, recipient: nil, toAddress: "0xABCDEF02", date: now.addingTimeInterval(-120)))
        try storage.save(swap: Self.swap(uid: "source", operation: .swap, recipient: nil, toAddress: "0xdeposit", sourceAddress: "0xabcdef03", date: now.addingTimeInterval(-180)))
        try storage.save(swap: Self.swap(uid: "other", operation: .swap, recipient: "0xother", toAddress: "0xother", sourceAddress: "0xother", date: now.addingTimeInterval(-240)))

        let matched = try storage.swaps(accountId: Self.accountId, addresses: ["0xabcdef01", "0xAbCdEf02", "0xABCDEF03"], limit: 10)
        let empty = try storage.swaps(accountId: Self.accountId, addresses: [], limit: 10)
        let all = try storage.swaps(accountId: Self.accountId, addresses: nil, limit: 10)

        #expect(matched.map(\.uid) == ["recipient", "to", "source"])
        #expect(empty.isEmpty)
        #expect(all.map(\.uid) == ["recipient", "to", "source", "other"])
    }

    @Test func combinedFiltersWithPagination() throws {
        let (storage, _) = try Self.storage()
        let now = Date()
        let address = "bc1qcontact"

        // Newest first: match-1, other-op, match-2, other-address, match-3
        try storage.save(swap: Self.swap(uid: "match-1", operation: .privateSend, recipient: address, date: now.addingTimeInterval(-60)))
        try storage.save(swap: Self.swap(uid: "other-op", operation: .swap, recipient: address, date: now.addingTimeInterval(-120)))
        try storage.save(swap: Self.swap(uid: "match-2", operation: .privateSend, recipient: address, date: now.addingTimeInterval(-180)))
        try storage.save(swap: Self.swap(uid: "other-address", operation: .privateSend, date: now.addingTimeInterval(-240)))
        try storage.save(swap: Self.swap(uid: "match-3", operation: .privateSend, recipient: address, date: now.addingTimeInterval(-300)))

        let firstPage = try storage.swaps(accountId: Self.accountId, addresses: [address], operations: [.privateSend], limit: 2)
        #expect(firstPage.map(\.uid) == ["match-1", "match-2"])

        let cursor = try #require(firstPage.last?.date)
        let secondPage = try storage.swaps(accountId: Self.accountId, addresses: [address], from: cursor, operations: [.privateSend], limit: 2)
        #expect(secondPage.map(\.uid) == ["match-3"])
    }
}

extension SwapStorageOperationTests {
    private static let accountId = "account"
    private static let token = Token(coin: Coin(uid: "bitcoin", name: "Bitcoin", code: "BTC"),
                                     blockchain: Blockchain(type: .bitcoin, name: "Bitcoin", explorerUrl: nil), type: .native, decimals: 8)
    private static let ethereumToken = Token(coin: Coin(uid: "ethereum", name: "Ethereum", code: "ETH"),
                                             blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil), type: .native, decimals: 18)
    private static let tronToken = Token(coin: Coin(uid: "tron", name: "Tron", code: "TRX"),
                                         blockchain: Blockchain(type: .tron, name: "Tron", explorerUrl: nil), type: .native, decimals: 6)
    private static let knownTokens = [token, ethereumToken, tronToken]

    private static func saveOneOfEachOperation(storage: SwapStorage) throws {
        try storage.save(swap: swap(uid: "swap", operation: .swap))
        try storage.save(swap: swap(uid: "private", operation: .privateSend))
        try storage.save(swap: swap(uid: "cross", operation: .crossPay))
        try storage.save(swap: swap(uid: "split", operation: .splitSwap))
    }

    private static func swap(
        uid: String,
        operation: Swap.Operation,
        trackingHandle: String? = nil,
        tokenIn: Token = token,
        tokenOut: Token = token,
        recipient: String? = "bc1qrecipient",
        toAddress: String = "bc1qrecipient",
        sourceAddress: String? = nil,
        date: Date = Date()
    ) -> Swap {
        Swap(
            uid: uid,
            txHash: nil,
            trackingHandle: trackingHandle,
            accountId: accountId,
            providerId: "NEAR",
            status: .notStarted,
            operation: operation,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: 1,
            amountOut: 1,
            recipient: recipient,
            toAddress: toAddress,
            depositAddress: "bc1qdeposit",
            providerSwapId: uid,
            sourceAddress: sourceAddress,
            refundAddress: nil,
            date: date
        )
    }

    /// The table as StorageMigrator leaves it; the migrator itself touches the app keychain, so it is not run here
    private static func storage() throws -> (SwapStorage, DatabasePool) {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("swap-storage-operation-tests-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)

        try dbPool.write { db in
            try db.create(table: SwapRecord.databaseTableName) { t in
                t.column(SwapRecord.Columns.uid.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(SwapRecord.Columns.txHash.name, .text)
                t.column(SwapRecord.Columns.trackingHandle.name, .text)
                t.column(SwapRecord.Columns.accountId.name, .text).notNull()
                t.column(SwapRecord.Columns.providerId.name, .text).notNull()
                t.column(SwapRecord.Columns.status.name, .text).notNull()
                t.column(SwapRecord.Columns.operation.name, .text).notNull().defaults(to: Swap.Operation.swap.rawValue)
                t.column(SwapRecord.Columns.tokenQueryIdIn.name, .text).notNull()
                t.column(SwapRecord.Columns.tokenQueryIdOut.name, .text).notNull()
                t.column(SwapRecord.Columns.amountIn.name, .text).notNull()
                t.column(SwapRecord.Columns.amountOut.name, .text).notNull()
                t.column(SwapRecord.Columns.recipient.name, .text)
                t.column(SwapRecord.Columns.toAddress.name, .text).notNull()
                t.column(SwapRecord.Columns.depositAddress.name, .text)
                t.column(SwapRecord.Columns.providerSwapId.name, .text)
                t.column(SwapRecord.Columns.sourceAddress.name, .text)
                t.column(SwapRecord.Columns.refundAddress.name, .text)
                t.column(SwapRecord.Columns.estimatedTime.name, .double)
                t.column(SwapRecord.Columns.date.name, .datetime).notNull()
                t.column(SwapRecord.Columns.fromAsset.name, .text)
                t.column(SwapRecord.Columns.toAsset.name, .text)
                t.column(SwapRecord.Columns.legs.name, .text)
                t.column(SwapRecord.Columns.pauseReason.name, .text)
                t.column(SwapRecord.Columns.outputs.name, .text)
            }
        }

        return (SwapStorage(dbPool: dbPool, marketKit: StubMarketKit()), dbPool)
    }

    private struct StubMarketKit: IMarketKit {
        func token(query _: TokenQuery) throws -> Token? {
            nil
        }

        func fullCoins(coinUids _: [String]) throws -> [FullCoin] {
            []
        }

        func tokens(queries: [TokenQuery]) throws -> [Token] {
            let ids = Set(queries.map(\.id))
            return SwapStorageOperationTests.knownTokens.filter { ids.contains($0.tokenQuery.id) }
        }
    }
}
