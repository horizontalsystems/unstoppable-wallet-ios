import Foundation
import GRDB
import MarketKit

class SwapStorage {
    private let dbPool: DatabasePool
    private let marketKit: MarketKit.Kit

    init(dbPool: DatabasePool, marketKit: MarketKit.Kit) {
        self.dbPool = dbPool
        self.marketKit = marketKit
    }

    private func swaps(records: [SwapRecord]) throws -> [Swap] {
        let tokenQueryIds = records.map(\.tokenQueryIdIn) + records.map(\.tokenQueryIdOut)
        let tokenQueries = tokenQueryIds.compactMap { TokenQuery(id: $0) }

        let tokens = try marketKit.tokens(queries: tokenQueries)
        let tokenMap = Dictionary(tokens.map { ($0.tokenQuery.id, $0) }, uniquingKeysWith: { first, _ in first })

        return records.compactMap { record in
            guard
                let tokenIn = tokenMap[record.tokenQueryIdIn],
                let tokenOut = tokenMap[record.tokenQueryIdOut],
                let amountIn = Decimal(string: record.amountIn),
                let amountOut = Decimal(string: record.amountOut)
            else {
                return nil
            }

            return Swap(
                uid: record.uid,
                txHash: record.txHash,
                accountId: record.accountId,
                providerId: record.providerId,
                status: Swap.Status(rawValue: record.status) ?? .unknown,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                recipient: record.recipient,
                toAddress: record.toAddress,
                depositAddress: record.depositAddress,
                providerSwapId: record.providerSwapId,
                date: record.date,
                fromAsset: record.fromAsset,
                toAsset: record.toAsset,
                legs: record.legs?.map { leg in
                    Swap.Leg(
                        status: Swap.Status(rawValue: record.status) ?? .unknown,
                        type: leg.type,
                        chainId: leg.chainId,
                        txHash: leg.txHash,
                        fromAsset: leg.fromAsset,
                        toAsset: leg.toAsset
                    )
                }
            )
        }
    }

    private func record(swap: Swap) -> SwapRecord {
        SwapRecord(
            uid: swap.uid,
            txHash: swap.txHash,
            accountId: swap.accountId,
            providerId: swap.providerId,
            status: swap.status.rawValue,
            tokenQueryIdIn: swap.tokenIn.tokenQuery.id,
            tokenQueryIdOut: swap.tokenOut.tokenQuery.id,
            amountIn: swap.amountIn.description,
            amountOut: swap.amountOut.description,
            recipient: swap.recipient,
            toAddress: swap.toAddress,
            depositAddress: swap.depositAddress,
            providerSwapId: swap.providerSwapId,
            date: swap.date,
            fromAsset: swap.fromAsset,
            toAsset: swap.toAsset,
            legs: swap.legs?.map { leg in
                SwapRecord.Leg(
                    status: leg.status.rawValue,
                    type: leg.type,
                    chainId: leg.chainId,
                    txHash: leg.txHash,
                    fromAsset: leg.fromAsset,
                    toAsset: leg.toAsset
                )
            }
        )
    }
}

extension SwapStorage {
    func swaps(accountId: String, from: Date? = nil, limit: Int) throws -> [Swap] {
        let records = try dbPool.read { db in
            var request = SwapRecord
                .filter(SwapRecord.Columns.accountId == accountId)
                .order(SwapRecord.Columns.date.desc)

            if let from {
                request = request.filter(SwapRecord.Columns.date < from)
            }

            return try request
                .limit(limit)
                .fetchAll(db)
        }

        return try swaps(records: records)
    }

    func pendingSwaps(accountId: String) throws -> [Swap] {
        let pendingStatuses = Swap.pendingStatuses.map(\.rawValue)

        let records = try dbPool.read { db in
            try SwapRecord
                .filter(SwapRecord.Columns.accountId == accountId && pendingStatuses.contains(SwapRecord.Columns.status))
                .order(SwapRecord.Columns.date.desc)
                .fetchAll(db)
        }

        return try swaps(records: records)
    }

    func save(swap: Swap) throws {
        _ = try dbPool.write { db in
            try record(swap: swap).insert(db)
        }
    }
}
