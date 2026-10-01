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
}

extension SwapStorageOperationTests {
    private static let accountId = "account"
    private static let token = Token(coin: Coin(uid: "bitcoin", name: "Bitcoin", code: "BTC"),
                                     blockchain: Blockchain(type: .bitcoin, name: "Bitcoin", explorerUrl: nil), type: .native, decimals: 8)

    private static func swap(uid: String, operation: Swap.Operation, trackingHandle: String? = nil) -> Swap {
        Swap(
            uid: uid,
            txHash: nil,
            trackingHandle: trackingHandle,
            accountId: accountId,
            providerId: "NEAR",
            status: .notStarted,
            operation: operation,
            tokenIn: token,
            tokenOut: token,
            amountIn: 1,
            amountOut: 1,
            recipient: "bc1qrecipient",
            toAddress: "bc1qrecipient",
            depositAddress: "bc1qdeposit",
            providerSwapId: uid,
            sourceAddress: nil,
            refundAddress: nil,
            date: Date()
        )
    }

    // The table as StorageMigrator leaves it; the migrator itself touches the app keychain, so it is not run here
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
            queries.map(\.id).contains(SwapStorageOperationTests.token.tokenQuery.id) ? [SwapStorageOperationTests.token] : []
        }
    }
}
